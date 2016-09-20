//
//  ViewController.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/23/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var numRepetitions: Int = 1 {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var numSections: Int = 10  {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var direction: UICollectionViewScrollDirection = .vertical {
        didSet {
            needsResetLayout = true
        }
    }
    
    var rowHeight: CGFloat = 100  {
        didSet {
            needsResetLayout = true
        }
    }

    var enforcesRowHeight: Bool = false  {
        didSet {
            needsResetLayout = true
        }
    }

    fileprivate var images = [UIImage](), needsResetLayout = false
    fileprivate let cellIdentifier = "cell", headerIdentifier = "header", footerIdentifier = "footer"

    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        
        let paths = Bundle.main.paths(forResourcesOfType: "jpg", inDirectory: "") 
        for path in paths {
            if let image = UIImage(contentsOfFile: path) {
                images.append(image)
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ZLBalancedFlowLayout"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self , action: #selector(ViewController.refreshButtonAction(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(ViewController.settingsButtonAction(_:)))

        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: cellIdentifier)
        collectionView?.register(LabelCollectionReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        collectionView?.register(LabelCollectionReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetLayoutIfNeeded(animated)
    }
    
    fileprivate func resetLayoutIfNeeded(_ animated: Bool) {
        if needsResetLayout {
            needsResetLayout = false
            
            let layout = ZLBalancedFlowLayout()
            layout.headerReferenceSize = CGSize(width: 100, height: 100)
            layout.footerReferenceSize = CGSize(width: 100, height: 100)
            layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            layout.scrollDirection = direction
            layout.rowHeight = rowHeight
            layout.enforcesRowHeight = enforcesRowHeight
            
            collectionView?.setCollectionViewLayout(layout, animated: true)
        }
    }

    // MARK: - Action
    func refreshButtonAction(_ sender:UIBarButtonItem) {
        self.collectionView?.reloadData()
    }
    
    func settingsButtonAction(_ sender:UIBarButtonItem) {
        SettingsViewController.presentInViewController(self)
    }
    
    // MARK: - UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numSections
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count*numRepetitions
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) 
        let imageView = UIImageView(image: imageForIndexPath(indexPath))
        imageView.contentMode = .scaleAspectFill
        cell.backgroundView = imageView
        cell.clipsToBounds = true
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var view = LabelCollectionReusableView(frame: CGRect.zero)
        switch (kind) {
        case UICollectionElementKindSectionHeader:
            view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, for: indexPath) as! LabelCollectionReusableView
            view.textLabel.text = "Header"
        case UICollectionElementKindSectionFooter:
            view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerIdentifier, for: indexPath) as! LabelCollectionReusableView
            view.textLabel.text = "Footer"
        default:
            view.textLabel.text = "N/A"
        }
        return view
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = imageForIndexPath(indexPath).size
        let percentWidth = CGFloat(UInt32(140) - arc4random_uniform(80))/100
        return CGSize(width: size.width*percentWidth/4, height: size.height/4)
    }
    
    // MARK: - ()
    func imageForIndexPath(_ indexPath:IndexPath) -> UIImage {
        return images[(indexPath as NSIndexPath).item%images.count]
    }
}

