#if canImport(AppKit) && !canImport(UIKit)
    import AppKit

    extension AppTerminalView {
        /// Ghostty keeps three IOSurface-backed frame states so GPU work can
        /// overlap. Occlusion stops new frames but intentionally retains those
        /// targets. Synchronously drawing three thumbnail frames advances
        /// through the whole swap chain and replaces every pane-sized target
        /// without resizing the terminal grid or its PTY.
        func compactRendererTargets() {
            guard !rendererTargetsCompacted,
                  let surface,
                  let layer
            else { return }

            let maximumDimension = max(layer.bounds.width, layer.bounds.height)
            guard maximumDimension > 0 else { return }

            let compactScale = max(
                1 / maximumDimension,
                min(layer.contentsScale, 64 / maximumDimension)
            )
            guard compactScale < layer.contentsScale else { return }

            rendererTargetsCompacted = true
            layer.contentsScale = compactScale
            for _ in 0..<3 {
                surface.draw()
            }
        }

        /// Rebuild every full-size frame before Ghostty is told the surface is
        /// visible, preventing a thumbnail frame or incremental reallocations
        /// from appearing while the user switches tabs.
        func restoreRendererTargets() {
            let needsMetricRestore = rendererTargetsCompacted
            rendererTargetsCompacted = false
            if needsMetricRestore {
                updateMetalLayerMetrics()
            }
            guard let surface else { return }
            for _ in 0..<3 {
                surface.draw()
            }
        }
    }
#endif
