//
//  ZLBalancedFlowLayout.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

open class ZLBalancedFlowLayout: UICollectionViewFlowLayout {
    /// The ideal row height of items in the grid
    open var rowHeight: CGFloat = 100 {
        didSet {
            invalidateLayout()
        }
    }

    /// The option to enforce the ideal row height by changing the aspect ratio of the item if necessary.
    open var enforcesRowHeight: Bool = false {
        didSet {
            invalidateLayout()
        }
    }

    fileprivate var headerFrames = [CGRect](), footerFrames = [CGRect]()
    fileprivate var itemFrames = [[CGRect]](), itemOriginYs = [[CGFloat]]()
    fileprivate var contentSize = CGSize.zero

    // TODO: shouldInvalidateLayoutForBoundsChange

    // MARK: - UICollectionViewLayout
    override open func prepare() {
        resetItemFrames()
        contentSize = CGSize.zero

        if let collectionView = self.collectionView {
            contentSize = scrollDirection == .vertical ?
                CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
                CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)

            for section in (0..<collectionView.numberOfSections) {
                headerFrames.append(self.collectionView(collectionView, frameForHeader: true, inSection: section, updateContentSize: &contentSize))

                let (frames, originYs) = self.collectionView(collectionView, framesForItemsInSection: section, updateContentSize: &contentSize)
                itemFrames.append(frames)
                itemOriginYs.append(originYs)

                footerFrames.append(self.collectionView(collectionView, frameForHeader: false, inSection: section, updateContentSize: &contentSize))
            }
        }
    }

    open func layoutAttributesForElements(in rect: CGRect) -> [AnyObject]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()

        if let collectionView = self.collectionView {
            // can be further optimized
            for section in (0..<collectionView.numberOfSections) {
                let sectionIndexPath = IndexPath(item: 0, section: section)
                if let headerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: sectionIndexPath) , headerAttributes.frame.size != CGSize.zero && headerAttributes.frame.intersects(rect) {
                    layoutAttributes.append(headerAttributes)
                }
                if let footerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionFooter, at: sectionIndexPath) , footerAttributes.frame.size != CGSize.zero && footerAttributes.frame.intersects(rect) {
                    layoutAttributes.append(footerAttributes)
                }
                var minY = CGFloat(0), maxY = CGFloat(0)
                if (scrollDirection == .vertical) {
                    minY = rect.minY-rect.height
                    maxY = rect.maxY
                } else {
                    minY = rect.minX-rect.width
                    maxY = rect.maxX
                }
                let lowerIndex = binarySearch(itemOriginYs[section], value: minY)
                let upperIndex = binarySearch(itemOriginYs[section], value: maxY)

                for item in lowerIndex..<upperIndex {
                    layoutAttributes.append(self.layoutAttributesForItem(at: IndexPath(item: item, section: section)))
                }
            }
        }
        return layoutAttributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        attributes?.frame = itemFrames[indexPath.section][indexPath.row]
        return attributes
    }

    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)

        switch (elementKind) {
        case UICollectionElementKindSectionHeader:
            attributes.frame = headerFrames[(indexPath as NSIndexPath).section]
        case UICollectionElementKindSectionFooter:
            attributes.frame = footerFrames[(indexPath as NSIndexPath).section]
        default:
            return nil
        }
        // If there is no header or footer, we need to return nil to prevent a crash from UICollectionView private methods.
        if(attributes.frame.isEmpty) {
            return nil;
        }

        return attributes
    }

    override open var collectionViewContentSize : CGSize {
        return contentSize
    }

    // MARK: - UICollectionViewLayout Helpers
    fileprivate func collectionView(_ collectionView:UICollectionView, frameForHeader isForHeader:Bool, inSection section:Int, updateContentSize contentSize:inout CGSize) -> CGRect {
        var size = referenceSizeForHeader(isForHeader, inSection: section), frame = CGRect.zero
        if (scrollDirection == .vertical) {
            frame = CGRect(x: 0, y: contentSize.height, width: collectionView.bounds.width, height: size.height);
            contentSize = CGSize(width: contentSize.width, height: contentSize.height+size.height)
        } else {
            frame = CGRect(x: contentSize.width, y: 0, width: size.width, height: collectionView.bounds.height);
            contentSize = CGSize(width: contentSize.width+size.width, height: contentSize.height)
        }
        return frame
    }

    fileprivate func collectionView(_ collectionView:UICollectionView, framesForItemsInSection section:Int, updateContentSize contentSize:inout CGSize) -> ([CGRect], [CGFloat]) {
        let maxWidth = Float(scrollDirection == .vertical ? contentSize.width : contentSize.height),
        widths = stride(from: 0, to: collectionView.numberOfItems(inSection: section), by: 1).map { (item: Int) -> Float in
            let itemSize = self.sizeForItemAtIndexPath(IndexPath(item: item, section: section)),
            ratio = self.scrollDirection == .vertical ?
                itemSize.width/itemSize.height :
                itemSize.height/itemSize.width
            return min(Float(ratio*self.rowHeight), Float(maxWidth))
        }
        // parition widths
        let partitions = partition(widths, max: Float(maxWidth))

        let minimumInteritemSpacing = minimumInteritemSpacingForSection(section),
        minimumLineSpacing = minimumLineSpacingForSection(section),
        inset = insetForSection(section)
        var framesInSection = [CGRect](), originYsInSection = [CGFloat](),
        origin = scrollDirection == .vertical ?
            CGPoint(x: inset.left, y: contentSize.height+inset.top) :
            CGPoint(x: contentSize.width+inset.left, y: inset.top)

        for row in partitions {
            // contentWidth/summedWidth
            let innerMargin = Float(CGFloat(row.count-1)*minimumInteritemSpacing),
            outterMargin = scrollDirection == .vertical ?
                Float(inset.left+inset.right) :
                Float(inset.top+inset.bottom),
            contentWidth = maxWidth - outterMargin - innerMargin,
            widthRatio = CGFloat(contentWidth/row.reduce(0, +)),
            heightRatio = enforcesRowHeight ? 1 : widthRatio
            for width in row {
                let size = scrollDirection == .vertical ?
                    CGSize(width: CGFloat(width)*widthRatio, height: rowHeight*heightRatio) :
                    CGSize(width: rowHeight*heightRatio, height: CGFloat(width)*widthRatio)
                let frame = CGRect(origin: origin, size: size)
                framesInSection.append(frame)
                if scrollDirection == .vertical {
                    origin = CGPoint(x: origin.x+frame.width+minimumInteritemSpacing, y: origin.y)
                    originYsInSection.append(origin.y)
                } else {
                    origin = CGPoint(x: origin.x, y: origin.y+frame.height+minimumInteritemSpacing)
                    originYsInSection.append(origin.x)
                }
            }
            if scrollDirection == .vertical {
                origin = CGPoint(x: inset.left, y: origin.y+framesInSection.last!.height+minimumLineSpacing)
            } else {
                origin = CGPoint(x: origin.x+framesInSection.last!.width+minimumLineSpacing, y: inset.top)
            }
        }

        if scrollDirection == .vertical {
            contentSize = CGSize(width: contentSize.width, height: origin.y+inset.bottom)
        } else {
            contentSize = CGSize(width: origin.x+inset.right, height: contentSize.height)
        }

        return (framesInSection, originYsInSection)
    }

    fileprivate func resetItemFrames() {
        headerFrames = [CGRect]()
        footerFrames = [CGRect]()
        itemFrames = [[CGRect]]()
        itemOriginYs = [[CGFloat]]()
    }

    // MARK: - Delegate Helpers
    fileprivate func referenceSizeForHeader(_ isForHeader: Bool, inSection section: Int) -> CGSize {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
            if isForHeader {
                if let size = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) {
                    return size
                }
            } else {
                if let size = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) {
                    return size
                }
            }
        }
        if isForHeader {
            return headerReferenceSize
        } else {
            return footerReferenceSize
        }
    }

    fileprivate func minimumLineSpacingForSection(_ section: Int) -> CGFloat {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, let minimumLineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) {
            return minimumLineSpacing
        }
        return minimumLineSpacing
    }

    fileprivate func minimumInteritemSpacingForSection(_ section: Int) -> CGFloat {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, let minimumInteritemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) {
            return minimumInteritemSpacing
        }
        return minimumInteritemSpacing
    }

    fileprivate func sizeForItemAtIndexPath(_ indexPath: IndexPath) -> CGSize {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt:indexPath) {
            return size
        }
        return itemSize
    }

    fileprivate func insetForSection(_ section: Int) -> UIEdgeInsets {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, let inset = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section){
          return inset
        }
        return sectionInset
    }

    // MARK: - ()
    fileprivate func binarySearch<T: Comparable>(_ array: Array<T>, value:T) -> Int{
        var imin=0, imax=array.count
        while imin<imax {
            let imid = imin+(imax-imin)/2

            if array[imid] < value {
                imin = imid+1
            } else {
                imax = imid
            }
        }
        return imin
    }

    // parition the widths in to rows using dynamic programming O(n^2)
    fileprivate func partition(_ values: [Float], max:Float) -> [[Float]] {
        let numValues = values.count
        if numValues == 0 {
            return []
        }

        var slacks = [[Float]](repeating: [Float](repeating: Float.infinity, count: numValues), count: numValues)
        for from in 0 ..< numValues {
            for to in from ..< numValues {
                let slack = to==from ? max-values[to] : slacks[from][to-1]-values[to]
                if slack >= 0 {
                    slacks[from][to] = slack
                } else {
                    break
                }
            }
        }

        // build up values of optimal solutions
        var opt = [Float](repeating: 0, count: numValues)
        opt[0] = pow(slacks[0][0], 2)
        for to in 1 ..< numValues {
            var minVal = Float.infinity
            
            for from in 0...to {
                let slack = pow(slacks[from][to], 2)
                if slack > pow(max, 2) {
                    continue
                }
                let opp = (from==0 ? 0 : opt[from-1])
                minVal = min(minVal, slack+opp)
            }
          
            /*
            for var from=0; from<=to; from += 1 {
                let slack = pow(slacks[from][to], 2)
                if slack > pow(max, 2) {
                    continue
                }
                let opp = (from==0 ? 0 : opt[from-1])
                minVal = min(minVal, slack+opp)
            }
                */
            opt[to] = minVal
        }

        // traceback the optimal solution
        var partitions = [[Float]]()
        findSolution(values, slacks: slacks, opt: opt, to: numValues-1, partitions: &partitions)
        return partitions
    }

    // traceback solution
    fileprivate func findSolution(_ values: [Float], slacks:[[Float]], opt: [Float], to: Int, partitions: inout [[Float]]) {
        if to<0 {
            partitions = partitions.reversed()
        } else {
            var minVal = Float.infinity, minIndex = 0
            
            
            for from in (0...to).reversed() {
                if slacks[from][to] == Float.infinity {
                    continue
                }
                
                let curVal = pow(slacks[from][to], 2) + (from==0 ? 0 : opt[from-1])
                if minVal > curVal {
                    minVal = curVal
                    minIndex = from
                }

            }
            
            /*
            for var from=to; from>=0; from -= 1 {
                if slacks[from][to] == Float.infinity {
                    continue
                }

                let curVal = pow(slacks[from][to], 2) + (from==0 ? 0 : opt[from-1])
                if minVal > curVal {
                    minVal = curVal
                    minIndex = from
                }
            }
            */
            
            partitions.append([Float](values[minIndex...to]))
            findSolution(values, slacks: slacks, opt: opt, to: minIndex-1, partitions: &partitions)
        }
    }

}
