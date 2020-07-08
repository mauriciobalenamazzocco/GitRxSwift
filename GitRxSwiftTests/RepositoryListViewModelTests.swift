//
//  RepositoryListViewModelTests.swift
//  GitRxSwiftTests
//
//  Created by Mauricio Balena Mazzocco on 05/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//
@testable import GitRxSwift

import Foundation
import XCTest
import RxSwift
import RxTest

class RepositoryListViewModelTests: XCTestCase {

    var disposeBag: DisposeBag!
    var githubService: GitServiceMock!
    var viewModel: RepositoryListViewModel!

    func getJsonMock() -> Data {
        let testBundle = Bundle(for: type(of: self))
        guard let filePath = testBundle.path(forResource: "RepositoryJsonMock", ofType: "txt")
            else { fatalError() }
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        return jsonData
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        githubService = GitServiceMock()
        viewModel = RepositoryListViewModel(gitService: githubService)
    }

    func test_Repositories_Count() {
        // Given
        guard let colectionResponse = try? JSONDecoder().decode(ApiCollectionResponseCodable<Repository>.self, from: getJsonMock()) else {
            return XCTFail()
        }
        let listPage : ListPage<Repository> = ListPage(items: colectionResponse.items, page: "fakePage", hasNext: false)
        githubService.repositoriesReturnValue =  .just(.success(listPage))

        let scheduler = TestScheduler(initialClock: 0)

        let obsTrigger = scheduler.createColdObservable([.next(0, ())])

        let reposObs = scheduler.createObserver([RepositoryCellViewModel].self)

        // When
        viewModel = RepositoryListViewModel(gitService: githubService)
        let output = viewModel.transform(input:
            .init(refresh: obsTrigger.asObservable().asDriver(onErrorJustReturn: ()))
        )

        output
            .repositories
            .subscribe(reposObs)
            .disposed(by: disposeBag)

        scheduler.start()

        // Then
        XCTAssertEqual(reposObs.events.count, 1)
        XCTAssertEqual(reposObs.events[0].value.element?.count, 30)
    }

    func test_Repositories_State() {
        // Given
        guard let colectionResponse = try? JSONDecoder().decode(ApiCollectionResponseCodable<Repository>.self, from: getJsonMock()) else {
            return XCTFail()
        }
        let listPage : ListPage<Repository> = ListPage(items: colectionResponse.items, page: "fakePage", hasNext: false)
        githubService.repositoriesReturnValue =  .just(.success(listPage))

        let scheduler = TestScheduler(initialClock: 0)

        let obsTrigger = scheduler.createColdObservable([.next(0, ())])

        let stateObs = scheduler.createObserver(State.self)

        // When
        viewModel = RepositoryListViewModel(gitService: githubService)
        let output = viewModel.transform(input:
            .init(refresh: obsTrigger.asObservable().asDriver(onErrorJustReturn: ()))
        )

        output
            .state
            .subscribe(stateObs)
            .disposed(by: disposeBag)

        scheduler.start()

        // Then
        XCTAssertEqual(stateObs.events.count, 3)
        XCTAssertEqual(stateObs.events[0].value.element, .idle)
        XCTAssertEqual(stateObs.events[1].value.element, .loadingPage)
        XCTAssertEqual(stateObs.events[2].value.element, .loadedPage(hasMore: false))
    }

    func test_Repositories_Error() {

        githubService.repositoriesReturnValue =  .just(.failure(.parseError))

        let scheduler = TestScheduler(initialClock: 0)

        let obsTrigger = scheduler.createColdObservable([.next(0, ())])

        let stateObs = scheduler.createObserver(State.self)

        viewModel = RepositoryListViewModel(gitService: githubService)
        let output = viewModel.transform(input:
            .init(refresh: obsTrigger.asObservable().asDriver(onErrorJustReturn: ()))
        )
        
        output
            .state
            .subscribe(stateObs)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(stateObs.events.count, 3)
        XCTAssertEqual(stateObs.events[0].value.element, .idle)
        XCTAssertEqual(stateObs.events[1].value.element, .loadingPage)
        XCTAssertEqual(stateObs.events[2].value.element, .error(.parseError))
    }
}

