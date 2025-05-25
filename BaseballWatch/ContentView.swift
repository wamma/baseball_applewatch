import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ScoreViewModel

    var body: some View {
        Text(viewModel.statusText)
            .font(.largeTitle)
            .onAppear {
                viewModel.start()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ScoreViewModel())
    }
}
