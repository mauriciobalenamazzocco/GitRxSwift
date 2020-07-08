//
//  RepositoryViewModel.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class RepositoryListViewModel: ViewModelProtocol, TableLoadMoreProtocol {

    private var repositories: [RepositoryCellViewModel] = []
    private let gitService: GitService

    private let _repositories = PublishRelay<[RepositoryCellViewModel]>()

    private var listPage: ListPage<Repository> = ListPage.first(items: [],
                                                                page: GitService.apiRepositoryPath,
                                                                hasNext: false)
    private var disposeBag = DisposeBag()
    private let _state = BehaviorRelay<State>(value: .idle)

    init(gitService: GitService = GitService()) {
        self.gitService = gitService
    }

    func transform(input: Input) -> Output {
        input.refresh.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self._state.accept(.loadingPage)
            self.repositories = []
            self.listPage = ListPage.first(items: [], page: GitService.apiRepositoryPath, hasNext: false)
            self.getRepositories()
        }).disposed(by: disposeBag)

        return Output(
            state: _state.asObservable(),
            repositories: _repositories.asObservable()
        )
    }

    private func getRepositories() {
        gitService.getRepositories(url: self.listPage.currentPage)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let listPage):
                    self.listPage = self.listPage.with(nextPage: listPage)
                    let models = listPage.items.map { repository -> RepositoryCellViewModel in
                        return RepositoryCellViewModel(
                            repository: repository
                        )
                    }
                    self.repositories.append(contentsOf: models)
                    self._repositories.accept(self.repositories)
                    self._state.accept(.loadedPage(hasMore: self.listPage.hasNext))
                case .failure(let error):
                    self._state.accept(.error(error))
                }
            }
        ).disposed(by: disposeBag)
    }

    func loadMore() {
        let isLoadingPage: Bool = { if case .loadingPage = _state.value { return true } else { return false } }()
        if !isLoadingPage && listPage.hasNext {
            self._state.accept(.loadingPage)
            getRepositories()
        }
    }
}

// MARK: - ViewModelProtocol
extension RepositoryListViewModel {
    struct Input {
        let refresh: Driver<Void>
    }

    struct Output {
        var state: Observable<State>
        var repositories: Observable<[RepositoryCellViewModel]>
    }
}
