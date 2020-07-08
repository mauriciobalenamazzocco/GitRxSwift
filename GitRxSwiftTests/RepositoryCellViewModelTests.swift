//
//  RepositoryCellViewModel.swift
//  GitRxSwiftTests
//
//  Created by Mauricio Balena Mazzocco on 06/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//
@testable import GitRxSwift

import Foundation
import XCTest
import RxSwift
import RxTest

class RepositoryCellViewModelTests: XCTestCase {

    var disposeBag: DisposeBag!
    var githubService: GitServiceMock!
    var viewModel: RepositoryCellViewModel!

    func getRepoJsonMock() -> Data {
        let testBundle = Bundle(for: type(of: self))
        guard let filePath = testBundle.path(forResource: "RepositoryJsonMock", ofType: "txt")
            else { fatalError() }
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        return jsonData
    }
    func getUserJsonMock() -> Data {
        let testBundle = Bundle(for: type(of: self))
        guard let filePath = testBundle.path(forResource: "UserJsonMock", ofType: "txt")
        else { fatalError() }
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        return jsonData
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        githubService = GitServiceMock()
    }

    func test_RepositoriyAllValues() {
        // Given
        guard let colectionResponse = try? JSONDecoder().decode(ApiCollectionResponseCodable<Repository>.self, from: getRepoJsonMock()) else {
            return XCTFail()
        }

        guard let user = try? JSONDecoder().decode(User.self, from: getUserJsonMock()) else {
                   return XCTFail()
            }

        let listPage : ListPage<Repository> = ListPage(items: colectionResponse.items, page: "", hasNext: false)

        githubService.repositoriesReturnValue =  .just(.success(listPage))
        githubService.userReturnValue = .just(.success(user))

        guard let repo = listPage.items.first else {
              return XCTFail()
        }

        let scheduler = TestScheduler(initialClock: 0)

        let repoNameObs = scheduler.createObserver(String.self)
        let starObs = scheduler.createObserver(String.self)
        let avatarObs = scheduler.createObserver(URL.self)
        let userNameObs = scheduler.createObserver(String.self)

        // When
        viewModel = RepositoryCellViewModel(repository: repo, gitService: githubService)
        let output = viewModel.transform(input: .init())

        output
            .repositoryName
            .drive(repoNameObs)
            .disposed(by: disposeBag)

        output
            .stars
            .drive(starObs)
            .disposed(by: disposeBag)

        output
            .avatar
            .map{ $0! }
            .drive(avatarObs)
            .disposed(by: disposeBag)

        output
            .userName
            .drive(userNameObs)
            .disposed(by: disposeBag)
        
        scheduler.start()

        // Then

        XCTAssertEqual(repoNameObs.events[0].value.element, " awesome-ios ")
        XCTAssertEqual(starObs.events[0].value.element, " • ⭐️35.2k")
        XCTAssertEqual(avatarObs.events[0].value.element, URL(string: "https://avatars2.githubusercontent.com/u/484656?v=4"))
        XCTAssertEqual(userNameObs.events[0].value.element, "Vinicius Souza")
    }
}
