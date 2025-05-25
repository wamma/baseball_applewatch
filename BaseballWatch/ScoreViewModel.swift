import Foundation
import Combine

class ScoreViewModel: ObservableObject {
    @Published var statusText: String = "loading"

    private var cancellables = Set<AnyCancellable>()

    func start() {
        fetchScore()
        // 1분마다 갱신
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchScore()
            }
            .store(in: &cancellables)
    }

    func fetchScore() {
        // TODO: API 호출 구현
        // 예시 데이터
        let myTeam = TeamSettings.myTeam
        // 점수 비교 로직을 여기에 구현
        let status = "win" // 혹은 draw/lose
        statusText = "\(myTeam): \(status)"
    }
}
