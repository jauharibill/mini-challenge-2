//
//  HeatmapPostProcessor.swift
//  Sprintastic
//
//  Created by Idris on 16/07/19.
//  Copyright © 2019 IdrisLabs. All rights reserved.
//
import Foundation
import CoreML

class HeatmapPostProcessor {
    func convertToPredictedPoints(from heatmaps: MLMultiArray) -> [PredictedPoint?] {
        guard heatmaps.shape.count >= 3 else {
            print("heatmap's shape is invalid. \(heatmaps.shape)")
            return []
        }
        let keypoint_number = heatmaps.shape[0].intValue
        let heatmap_w = heatmaps.shape[1].intValue
        let heatmap_h = heatmaps.shape[2].intValue
        
        var n_kpoints = (0..<keypoint_number).map { _ -> PredictedPoint? in
            return nil
        }
        
        for k in 0..<keypoint_number {
            for i in 0..<heatmap_w {
                for j in 0..<heatmap_h {
                    let index = k*(heatmap_w*heatmap_h) + i*(heatmap_h) + j
                    let confidence = heatmaps[index].doubleValue
                    guard confidence > 0 else { continue }
                    if n_kpoints[k] == nil ||
                        (n_kpoints[k] != nil && n_kpoints[k]!.maxConfidence < confidence) {
                        n_kpoints[k] = PredictedPoint(maxPoint: CGPoint(x: CGFloat(j), y: CGFloat(i)), maxConfidence: confidence)
                    }
                }
            }
        }
        
        // transpose to (1.0, 1.0)
        n_kpoints = n_kpoints.map { kpoint -> PredictedPoint? in
            if let kp = kpoint {
                return PredictedPoint(maxPoint: CGPoint(x: (kp.maxPoint.x+0.5)/CGFloat(heatmap_w),
                                                        y: (kp.maxPoint.y+0.5)/CGFloat(heatmap_h)),
                                      maxConfidence: kp.maxConfidence)
            } else {
                return nil
            }
        }
        
        return n_kpoints
    }
    
    func convertTo3DArray(from heatmaps: MLMultiArray) -> Array<Array<Double>> {
        guard heatmaps.shape.count >= 3 else {
            print("heatmap's shape is invalid. \(heatmaps.shape)")
            return []
        }
        let keypoint_number = heatmaps.shape[0].intValue
        let heatmap_w = heatmaps.shape[1].intValue
        let heatmap_h = heatmaps.shape[2].intValue
        
        var convertedHeatmap: Array<Array<Double>> = Array(repeating: Array(repeating: 0.0, count: heatmap_h), count: heatmap_w)
        
        for k in 0..<keypoint_number {
            for i in 0..<heatmap_w {
                for j in 0..<heatmap_h {
                    let index = k*(heatmap_w*heatmap_h) + i*(heatmap_h) + j
                    let confidence = heatmaps[index].doubleValue
                    guard confidence > 0 else { continue }
                    convertedHeatmap[j][i] += confidence
                }
            }
        }
        
        convertedHeatmap = convertedHeatmap.map { row in
            return row.map { element in
                if element > 1.0 {
                    return 1.0
                } else if element < 0 {
                    return 0.0
                } else {
                    return element
                }
            }
        }
        
        return convertedHeatmap
    }
}
