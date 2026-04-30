//! Recorder -> ASR bridge that buffers PCM until the streaming session attaches.
//!
//! Mirrors the Swift `BufferingAudioConsumer`: recording starts immediately,
//! early chunks are retained, then drained in order once ASR is ready.

use std::sync::Arc;

use parking_lot::Mutex;

struct BufferState {
    target: Option<Arc<dyn crate::asr::AudioConsumer>>,
    buffered_chunks: Vec<Vec<u8>>,
    buffered_byte_count: usize,
}

pub struct BufferingAudioConsumer {
    max_buffered_bytes: usize,
    state: Mutex<BufferState>,
}

impl BufferingAudioConsumer {
    pub fn new(max_buffered_bytes: usize) -> Self {
        Self {
            max_buffered_bytes,
            state: Mutex::new(BufferState {
                target: None,
                buffered_chunks: Vec::new(),
                buffered_byte_count: 0,
            }),
        }
    }

    pub fn attach(&self, target: Arc<dyn crate::asr::AudioConsumer>) {
        let pending = {
            let mut state = self.state.lock();
            state.target = Some(Arc::clone(&target));
            state.buffered_byte_count = 0;
            std::mem::take(&mut state.buffered_chunks)
        };

        for chunk in pending {
            target.consume_pcm_chunk(&chunk);
        }
    }

    pub fn clear(&self) {
        let mut state = self.state.lock();
        state.target = None;
        state.buffered_chunks.clear();
        state.buffered_byte_count = 0;
    }
}

impl crate::recorder::AudioConsumer for BufferingAudioConsumer {
    fn consume_pcm_chunk(&self, pcm: &[u8]) {
        let target = {
            let mut state = self.state.lock();
            if let Some(target) = state.target.as_ref() {
                Some(Arc::clone(target))
            } else {
                state.buffered_chunks.push(pcm.to_vec());
                state.buffered_byte_count += pcm.len();

                while state.buffered_byte_count > self.max_buffered_bytes {
                    if let Some(chunk) = state.buffered_chunks.first() {
                        state.buffered_byte_count -= chunk.len();
                    }
                    if state.buffered_chunks.is_empty() {
                        break;
                    }
                    state.buffered_chunks.remove(0);
                }
                None
            }
        };

        if let Some(target) = target {
            target.consume_pcm_chunk(pcm);
        }
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use parking_lot::Mutex;

    use super::BufferingAudioConsumer;
    use crate::recorder::AudioConsumer;

    #[derive(Default)]
    struct FakeAsrConsumer {
        chunks: Mutex<Vec<Vec<u8>>>,
    }

    impl crate::asr::AudioConsumer for FakeAsrConsumer {
        fn consume_pcm_chunk(&self, pcm: &[u8]) {
            self.chunks.lock().push(pcm.to_vec());
        }
    }

    #[test]
    fn replays_buffered_chunks_in_order_then_streams_directly() {
        let buffering = BufferingAudioConsumer::new(1024);
        buffering.consume_pcm_chunk(b"ab");
        buffering.consume_pcm_chunk(b"cd");

        let target = Arc::new(FakeAsrConsumer::default());
        let asr_target: Arc<dyn crate::asr::AudioConsumer> = target.clone();
        buffering.attach(asr_target);
        buffering.consume_pcm_chunk(b"ef");

        assert_eq!(
            *target.chunks.lock(),
            vec![b"ab".to_vec(), b"cd".to_vec(), b"ef".to_vec()]
        );
    }

    #[test]
    fn drops_oldest_chunks_when_buffer_limit_is_exceeded() {
        let buffering = BufferingAudioConsumer::new(4);
        buffering.consume_pcm_chunk(b"ab");
        buffering.consume_pcm_chunk(b"cd");
        buffering.consume_pcm_chunk(b"ef");

        let target = Arc::new(FakeAsrConsumer::default());
        let asr_target: Arc<dyn crate::asr::AudioConsumer> = target.clone();
        buffering.attach(asr_target);

        assert_eq!(*target.chunks.lock(), vec![b"cd".to_vec(), b"ef".to_vec()]);
    }
}
