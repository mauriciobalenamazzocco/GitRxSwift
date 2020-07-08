//
//  RepositoryTableViewCell.swift
//  GitRxSwift
//
//  Created by Mauricio Balena Mazzocco on 03/07/20.
//  Copyright © 2020 Mauricio Balena Mazzocco. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class RepositoryCell: UITableViewCell, ClassIdentifiable {

    private var disposeBag = DisposeBag()
    typealias ViewModelType = RepositoryCellViewModel
    var viewModel: ViewModelType!

    lazy var avatarImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        img.layer.cornerRadius = 35
        img.clipsToBounds = true
        return img
    }()

    lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var repositoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor =  .white
        label.backgroundColor = R.color.gitBlue()
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var starsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var hStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [repositoryNameLabel, starsLabel])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var vStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [userNameLabel, hStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var avatarImageBinder = Binder<URL?>(self) {strongSelf, url in
        strongSelf.avatarImageView.kf.setImage(
            with: url,
            placeholder: R.image.userPlaceholder(),
            options: [
            ]
        )
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(avatarImageView)
        self.contentView.addSubview(vStackView)
        backgroundColor  = .white
        selectionStyle = .none
        avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor,
                                                  constant: 10).isActive = true

        avatarImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        vStackView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

        vStackView.leadingAnchor.constraint(
            equalTo: self.avatarImageView.trailingAnchor,
            constant: 10).isActive = true

        self.contentView.trailingAnchor.constraint(
            equalTo: self.vStackView.trailingAnchor,
            constant: 10
        ).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

extension RepositoryCell: BindableType {
    func bindViewModel() {
        let outputs = viewModel.transform(input:
            .init()
        )

        outputs
            .stars
            .drive(starsLabel.rx.text)
            .disposed(by: disposeBag)

        outputs
            .userName
            .drive(onNext: { [weak self] name in
                guard let self = self else { return }
                self.userNameLabel.text = name

            })
            .disposed(by: disposeBag)

        outputs
            .repositoryName
            .drive(repositoryNameLabel.rx.text)
            .disposed(by: disposeBag)

        outputs
            .avatar
            .asObservable()
            .bind(to: avatarImageBinder)
            .disposed(by: disposeBag)
    }
}
