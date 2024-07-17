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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLeftBackButton()
        setTitleLabelStyle(title: StringLiterals.PointDetail.title, alignment: .center)
        setProfile(userName: "수민", totalPoint: 200) // 나중에 푸쉬 전 뷰(메인뷰, 마이페이지뷰)에서 실행
        registerCell()
        setDelegate()
        setAddTarget()
        bindViewModel()
        changeSelectedSegmentLayout(isEarnedPointHidden: false)
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
        self.pointViewModel.nowPointData.bind { [weak self] data in
            self?.pointDetailView.pointCollectionView.reloadData()
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
        print(view)
    }
    
    func changeSelectedSegmentLayout(isEarnedPointHidden: Bool?) {
        guard let isEarnedPointHidden = isEarnedPointHidden else { return }
        print(isEarnedPointHidden)
        if isEarnedPointHidden {
            switch pointViewModel.usedDummyData.value?.count == 0 {
            case true:
                setSegmentViewHidden(pointDetailView.emptyUsedPointView)
            case false:
                setSegmentViewHidden(pointDetailView.pointCollectionView)
                pointDetailView.pointCollectionView.reloadData()
            }
            
            pointDetailView.selectedSegmentUnderLineView.snp.updateConstraints {
                $0.leading.equalToSuperview().inset(ScreenUtils.width/2)
            }
        } else {
            switch pointViewModel.gainedDummyData.value?.count == 0 {
            case true:
                setSegmentViewHidden(pointDetailView.emptyGainedPointView)
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
        pointViewModel.updateData(nowEarnedPointHidden: pointViewModel.isEarnedPointHidden.value ?? false)
        cell.prepareForReuse()
        let data = pointViewModel.nowPointData.value?[indexPath.item] ?? PointDetailModel(sign: "", point: 0, description: "", createAt: "")
        cell.dataBind(data, indexPath.item)
        return cell
    }
}
