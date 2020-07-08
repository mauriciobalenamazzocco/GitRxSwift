//
//  RepositoryCellViewModel.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//
import Foundation
import XCoordinator

enum RepositoryCoordinatorRoute: Route {
    case repository
}

class RepositoryCoordinator: NavigationCoordinator<RepositoryCoordinatorRoute> {
    init() {
        let navigation = UINavigationController()
        navigation.modalPresentationStyle = .fullScreen
        navigation.navigationBar.barStyle = .default
        navigation.navigationBar.isTranslucent = false
        navigation.navigationBar.barTintColor = R.color.gitBlue()

        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = R.color.gitBlue()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().tintColor = .white
            navigation.navigationBar.backgroundColor = R.color.gitBlue()
            navigation.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }

        super.init(rootViewController: navigation, initialRoute: .repository)
    }

    override func prepareTransition(for route: RepositoryCoordinatorRoute) -> NavigationTransition {
        switch route {
        case .repository:
            var controller = RepositoryListViewController()
            let model = RepositoryListViewModel()
            controller.bind(to: model)
            return .push(controller)

        }
    }
}
