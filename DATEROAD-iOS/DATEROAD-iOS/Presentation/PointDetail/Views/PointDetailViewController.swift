//
//  PointDetailsViewController.swift
//  DATEROAD-iOS
//
//  Created by 이수민 on 7/3/24.
//

import UIKit

import SnapKit
import Then

class PointDetailViewController: BaseNavBarViewController {
    
    // MARK: - UI Properties
    
    private let pointDetailView = PointDetailView()
        
    private let errorView: DRErrorViewController = DRErrorViewController()
    
    // MARK: - Properties
    
    private var pointViewModel: PointViewModel
    
    // MARK: - LifeCycle
    
    init(pointViewModel: PointViewModel) {
        self.pointViewModel = pointViewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.pointViewModel.setPointDetailLoading()
        self.pointViewModel.getPointDetail(nowEarnedPointHidden: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLeftBackButton()
        setTitleLabelStyle(title: StringLiterals.PointDetail.title, alignment: .center)
        setProfile(userName: pointViewModel.userName, totalPoint: pointViewModel.totalPoint)
        registerCell()
        setDelegate()
        setAddTarget()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func setHierarchy() {
        super.setHierarchy()
                
        self.contentView.addSubviews(pointDetailView)
    }
    
    override func setLayout() {
        super.setLayout()
        
        pointDetailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

}


extension PointDetailViewController {
    func bindViewModel() {
        self.pointViewModel.onFailNetwork.bind { [weak self] onFailure in
            guard let onFailure else { return }
            if onFailure {
                self?.hideLoadingView()
                let errorVC = DRErrorViewController()
                self?.navigationController?.pushViewController(errorVC, animated: false)
            }
        }

        self.pointViewModel.onLoading.bind { [weak self] onLoading in
            guard let onLoading, let onFailNetwork = self?.pointViewModel.onFailNetwork.value else { return }
            if !onFailNetwork {
                onLoading ? self?.showLoadingView() : self?.hideLoadingView()
                self?.pointDetailView.isHidden = onLoading
            }
        }
        
        self.pointViewModel.isSuccessGetPointInfo.bind { [weak self] isSuccess in
            guard let isSuccess else { return }
            if isSuccess {
                self?.pointDetailView.pointCollectionView.reloadData()
                self?.pointViewModel.updateData(nowEarnedPointHidden: false)
                self?.changeSelectedSegmentLayout(isEarnedPointHidden: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.pointViewModel.setPointDetailLoading()
                }
            }
        }
        
    }
    
    func setProfile(userName: String, totalPoint: Int) {
        pointDetailView.userNameLabel.text = "\(userName) 님의 포인트"
        pointDetailView.totalPointLabel.text = "\(totalPoint) P"
    }
    
    private func setAddTarget() {
        pointDetailView.segmentControl.addTarget(self, action: #selector(didChangeValue(segment:)), for: .valueChanged)
    }
}

// MARK: - Private Method

private extension PointDetailViewController {
    @objc
    func didChangeValue(segment: UISegmentedControl) {
        pointViewModel.changeSegment(segmentIndex: pointDetailView.segmentControl.selectedSegmentIndex)
        changeSelectedSegmentLayout(isEarnedPointHidden: pointViewModel.isEarnedPointHidden.value)
    }
    
    func setSegmentViewHidden(_ view: UIView) {
        pointDetailView.pointCollectionView.isHidden = true
        pointDetailView.emptyUsedPointView.isHidden = true
        pointDetailView.emptyGainedPointView.isHidden = true
        view.isHidden = false
    }
    
    func changeSelectedSegmentLayout(isEarnedPointHidden: Bool?) {
        guard let isEarnedPointHidden = isEarnedPointHidden else { return }
        if isEarnedPointHidden {
            switch pointViewModel.usedPointData.value?.count == 0 {
            case true:
                setSegmentViewHidden(pointDetailView.emptyUsedPointView)
                pointDetailView.pointCollectionView.reloadData()
            case false:
                setSegmentViewHidden(pointDetailView.pointCollectionView)
                pointDetailView.pointCollectionView.reloadData()
            }
            
            pointDetailView.selectedSegmentUnderLineView.snp.updateConstraints {
                $0.leading.equalToSuperview().inset(ScreenUtils.width/2)
            }
        } else {
            switch pointViewModel.gainedPointData.value?.count == 0 {
            case true:
                setSegmentViewHidden(pointDetailView.emptyGainedPointView)
                pointDetailView.pointCollectionView.reloadData()
            case false:
                setSegmentViewHidden(pointDetailView.pointCollectionView)
                pointDetailView.pointCollectionView.reloadData()
            }

            pointDetailView.selectedSegmentUnderLineView.snp.updateConstraints {
                $0.leading.equalToSuperview()
            }
        }
    }
}


// MARK: - CollectionView Methods

extension PointDetailViewController {
    private func registerCell() {
        pointDetailView.pointCollectionView.register(PointCollectionViewCell.self, forCellWithReuseIdentifier: PointCollectionViewCell.cellIdentifier)
    }
    
    private func setDelegate() {
        pointDetailView.pointCollectionView.delegate = self
        pointDetailView.pointCollectionView.dataSource = self
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PointDetailViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ScreenUtils.width, height: 86)
    }
}

// MARK: - UICollectionViewDataSource

extension PointDetailViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pointViewModel.nowPointData.value?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PointCollectionViewCell.cellIdentifier, for: indexPath) as? PointCollectionViewCell else { return UICollectionViewCell() }
        let data = pointViewModel.nowPointData.value?[indexPath.item] ?? PointDetailModel(sign: "", point: 0, description: "", createdAt: "")
        cell.dataBind(data, indexPath.item)
        return cell
    }
}
