//
//  RepositoryCellViewModel.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import Kingfisher
import RxCocoa

//swiftlint:disable empty_enum_arguments
class RepositoryCellViewModel: CellViewModelProtocol, PrefetchImageProtocol {
    private var userNameText: String?
    private var startsText: String?
    private var avatarURL: URL?
    private var repositoryName: String?
    private var repositoryPath: String!
    private var disposeBag = DisposeBag()
    private var gitService: GitService!
    private var userNameMemory: String?
    private let _user = BehaviorRelay<String>(value: "")

    init(repository: Repository,
         gitService: GitService = GitService()) {

        self.gitService = gitService
        if let avatarImage = repository.owner?.avatarUrl {
            avatarURL = URL(string: avatarImage)
        }

        if let repositoryPath = repository.owner?.url {
            self.repositoryPath = repositoryPath
        }

        repositoryName = repository.name
        startsText = formatStarText(starsCount: repository.starsCount ?? 0)
    }

    func transform(input: Input) -> Output {
        if let userNameMem = userNameMemory {
            self._user.accept(userNameMem)
        } else {
            self.gitService.getUser(url: repositoryPath)
                .observeOn(MainScheduler())
                .subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }

                    switch result {
                    case .success(let user ):
                        self.userNameMemory = user.name
                        self._user.accept(self.userNameMemory ?? "")
                    case .failure(_ ):  break // Treat error, in this case the user name will be empty.
                    }
                })
                .disposed(by: disposeBag)
        }

        return  Output(userName: _user.asDriver(),
                       repositoryName: .just(formatRepositoryText(repositoryName: repositoryName)),
                       stars: .just(startsText ?? ""),
                       avatar: .just(avatarURL)
        )
    }

    func prefetch() {
        if let avatarurl = self.avatarURL {
            ImagePrefetcher(
                urls: [avatarurl]
            )
            .start()
        }
    }

    func prepareForReuse() {
        disposeBag = DisposeBag()
    }

    private func formatRepositoryText(repositoryName: String?) -> String {
        return " \(repositoryName ?? "") "
    }

    //Like github Format
    private func formatStarText(starsCount: Int64) -> String {
        if starsCount > 1000 {
            let convertedValue: Double = Double(starsCount) / 1000
            let format = String(format: "%2.1f", convertedValue)
            let doubleFormat = Double(format)
            let isInteger = floor(doubleFormat ?? 0) == doubleFormat
            if isInteger {
                return " • ⭐️\(Int(convertedValue.rounded()))k "
            } else {
                return  " • ⭐️\(format)k"
            }
        }
        return  " • ⭐️\(starsCount)"
    }
}

extension RepositoryCellViewModel {
    struct Input {
    }

    struct Output {
        let userName: Driver<String>
        let repositoryName: Driver<String>
        let stars: Driver<String>
        let avatar: Driver<URL?>

    }
}
