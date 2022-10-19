import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: Image?

    func load(url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let nsImage = NSImage(data: data) else { return }
            image = Image(nsImage: nsImage)
        } catch {
            print(error)
        }
    }

}

struct MyAsyncImage<Placeholder: View>: View {
    var url: URL
    @ViewBuilder var placeholder: Placeholder
    private var _resizable = false
    @StateObject private var loader = ImageLoader()

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
    }

    var body: some View {
        MyUnmanagedAsyncImage(url: url, loader: loader, resizable: _resizable, placeholder: { placeholder })
    }

    func resizable() -> Self {
        var copy = self
        copy._resizable = true
        return copy
    }
}

struct MyUnmanagedAsyncImage<Placeholder: View>: View {
    init(url: URL, loader: ImageLoader, resizable: Bool, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
        self.loader = loader
        self._resizable = resizable
    }

    var url: URL
    @ViewBuilder var placeholder: Placeholder
    private var _resizable = false
    @ObservedObject private var loader: ImageLoader

    var body: some View {
        ZStack {
            if let image = loader.image {
                if _resizable {
                    image.resizable()
                } else {
                    image
                }
            } else {
                placeholder

            }
        }.task(id: url) {
            await loader.load(url: url)
        }
    }

    func resizable() -> Self {
        var copy = self
        copy._resizable = true
        return copy
    }
}

struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 100))]) {
                ForEach(Photo.sample) { photo in
                    MyAsyncImage(url: photo.urls.thumb, placeholder: {
                        Color.gray
                    })
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
