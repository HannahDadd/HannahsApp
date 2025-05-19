import SwiftUI
import CoreMotion
import AVFoundation

struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let words = ["words", "here"]

    var body: some View {
        VStack {
            if vm.wordIndex >= words.count {
                Text("No more words! Head to the pub!")
                    .font(.largeTitle)
            } else if vm.timeRemaining > 120 {
                Text("Put me on your head")
                    .font(.largeTitle)
            } else if vm.timeRemaining == 0 {
                Spacer()
                Text("Time's Up!")
                    .font(.largeTitle)
                Spacer()
                Text("You scored \(vm.score)")
                    .font(.largeTitle)
                Spacer()
                Button("Play again") {
                    vm.resetGame()
                    vm.timeRemaining = 20
                }
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Text("Time remaining: \(vm.timeRemaining)")
                }
                Spacer()
                switch vm.viewState {
                case .question:
                    Text(words[vm.wordIndex])
                        .font(.largeTitle)
                case .correct:
                    Text("Correct!")
                        .font(.largeTitle)
                case .wrong:
                    Text("Whoops!")
                        .font(.largeTitle)
                }
                Spacer()
            }
        }
        .padding()
        .background(getBGColor())
        .onReceive(timer) { _ in
            if vm.timeRemaining > 0 {
                vm.timeRemaining -= 1
            }
        }
        .onAppear {
            vm.onAppear()
        }
    }

    private func getBGColor() -> Color {
        switch vm.viewState {
        case .correct:
            return .green
        case .wrong:
            return .red
        default:
            return .white
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var viewState: ViewState = .question
    @Published var timeRemaining = 20
    var score = 0
    var wordIndex = 0

    let mm = CMMotionManager()
    var isProcessing = false

    func onAppear() {
        mm.startAccelerometerUpdates(to: OperationQueue.main, withHandler: {
            [weak self] (data: CMAccelerometerData!, _) in
            if (self?.isProcessing != nil && self?.isProcessing == true) {
                return
            }
            guard let self = self else { return }
            if self.viewState == .question && self.timeRemaining > 0 && self.timeRemaining < 120 {
                if(data.acceleration.z > 0.9) {
                    self.isProcessing = true
                    self.viewState = .correct
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    AudioServicesPlaySystemSound(1002)
                    self.wordIndex += 1
                    self.score += 1
                    // try await Task.sleep(for: .seconds(3))
                    let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
                        self.viewState = .question
                        self.isProcessing = false
                    }
                } else if (data.acceleration.z < -0.9){
                    self.isProcessing = true
                    self.viewState = .wrong
                    self.wordIndex += 1
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    AudioServicesPlaySystemSound(1016)
                    // try await Task.sleep(for: .seconds(3))
                    let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
                        self.viewState = .question
                        self.isProcessing = false
                    }
                }
            }
            return
        })
    }

    func resetGame() {
        score = 0
        viewState = .question
    }
}

enum ViewState {
    case correct, wrong, question
}
