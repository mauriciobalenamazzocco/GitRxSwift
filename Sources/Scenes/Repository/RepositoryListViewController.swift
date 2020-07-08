//
//  RepositoryViewController.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

class RepositoryListViewController: UIViewController {
    var viewModel: RepositoryListViewModel!

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 100
        table.showsVerticalScrollIndicator = false
        table.estimatedRowHeight = 100
        table.backgroundColor = .white
        table.delegate = self
        table.prefetchDataSource = self
        table.refreshControl = refreshControl
        table.register(RepositoryCell.self, forCellReuseIdentifier: RepositoryCell.reuseId)
        table.tableFooterView = nextPageProgressIndicator
        return table
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = R.color.gitBlue()
        return refresh
    }()

    private lazy var nextPageProgressIndicator: UIActivityIndicatorView = {
        let progress = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        progress.color = R.color.gitBlue()
        progress.hidesWhenStopped = true
        progress.frame = .init(x: 0, y: 0, width: 44, height: 44)
        return progress
    }()

    private lazy var loadingView: UIActivityIndicatorView = {
         let progress = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
         progress.color = R.color.gitBlue()
         progress.hidesWhenStopped = true
         progress.frame = .init(x: 0, y: 0, width: 44, height: 44)
         progress.translatesAutoresizingMaskIntoConstraints = false
         return progress
     }()

    private let disposeBag = DisposeBag()
    private var showingAlert = false
    private typealias RepositorySectionViewModel = SectionModel<String, RepositoryCellViewModel>
    private var repositoryDataSource: RxTableViewSectionedReloadDataSource<RepositorySectionViewModel>!
    private var repositoryListDataSourceCellConfiguration: TableViewSectionedDataSource<RepositorySectionViewModel>.ConfigureCell {
        return {_, tableView, indexPath, cellViewModel in
            let cell = tableView.dequeueReusableCell(withIdentifier: RepositoryCell.reuseId, for: indexPath)
            if var cellRepository = cell as? RepositoryCell {
                cellRepository.bind(to: cellViewModel)
                return cellRepository

            }
            return  UITableViewCell()

        }
    }

    private lazy var stateBinder = Binder<State>(self) {strongSelf, state in

        switch state {
        case .idle:
            print("idle")

        case .loadingPage:
            print("loadingPage")

        case .loadedPage(let hasMore):
            strongSelf.loadingView.stopAnimating()
            if hasMore {
                strongSelf.nextPageProgressIndicator.isHidden = false
                strongSelf.nextPageProgressIndicator.startAnimating()
            } else {
                strongSelf.nextPageProgressIndicator.stopAnimating()
            }
            strongSelf.refreshControl.endRefreshing()
        case .error(let error):

            if strongSelf.refreshControl.isRefreshing { strongSelf.refreshControl.endRefreshing() }
            strongSelf.nextPageProgressIndicator.isHidden = true
            var errorString = ""
            switch error {
            case .parseError:
                errorString = NSLocalizedString("apiErrorLimit", comment: "")
            case .urlInvalid:
                errorString = NSLocalizedString("invalidUrl", comment: "")
            }
            strongSelf.showError(error: errorString)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("repositories", comment: "")
        view.backgroundColor = .white
        setupElements()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
          setupConstraints()
    }

    private func setupConstraints() {
        view.addSubview(tableView)
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupElements() {
        loadingView.startAnimating()
        nextPageProgressIndicator.isHidden = true
        repositoryDataSource = RxTableViewSectionedReloadDataSource<RepositorySectionViewModel>(
            configureCell: repositoryListDataSourceCellConfiguration
        )
    }

    func showError(error: String) {

           if !showingAlert {
               let alert = UIAlertController(
                   title: NSLocalizedString("error", comment: ""),
                   message: error,
                   preferredStyle: UIAlertController.Style.alert
               )

               alert.addAction(
                   UIAlertAction(
                       title: NSLocalizedString("ok", comment: ""),
                       style: UIAlertAction.Style.default,
                       handler: { [weak self] _ in
                           self?.showingAlert = false
                       }
                   )
               )
               self.present(alert, animated: true, completion: nil)
           }

            showingAlert = true
       }
}

extension RepositoryListViewController: BindableType {
    func bindViewModel() {
        let outputs = viewModel.transform(input:
            .init(
                refresh: refreshControl.rx.controlEvent(.valueChanged).asDriver().startWith(()))
        )

        outputs
            .repositories
            .map { [RepositorySectionViewModel(model: "", items: $0)] }
            .bind(to: tableView.rx.items(dataSource: repositoryDataSource))
            .disposed(by: disposeBag)

        outputs
            .state
            .bind(to: stateBinder)
            .disposed(by: disposeBag)
    }
}

//Prefetch images
extension RepositoryListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths
            .map { repositoryDataSource.sectionModels[0].items[$0.row] }
            .forEach { model in
                model.prefetch()
            }
        }
    }

extension RepositoryListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

           if indexPath.row >= (repositoryDataSource.sectionModels[0].items.count - 15) {
            viewModel.loadMore()
        }
    }
}
