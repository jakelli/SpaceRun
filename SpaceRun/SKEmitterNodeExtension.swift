//
//  SKEmitterNodeExtension.swift
//  SpaceRun
//
//  Created by Jake Ellious on 4/27/16.
//  Copyright © 2016 Jake Ellious. All rights reserved.
//

import SpriteKit

// Use a swift extension to extend the string class
extension String {
    var length: Int{
        return self.characters.count
    }
}


extension SKEmitterNode{
    // Helper method fetch the passed in particle effect file
    class func pdc_nodeWithFile(_ fileName:String) -> SKEmitterNode? {
        
        // We will check the file base name and extension.
        // If there is no extension on file name, then we will set it to .sks
        let baseName = (fileName as NSString).deletingPathExtension // check base file name
        var fileExt = (fileName as NSString).pathExtension // check file extension
        
        if fileExt.length == 0 {
            fileExt = "sks"
        }
        
        // We will grab the main bundle of our project and ask for the path to a resource
        // that has the calculated base name and file extension
        if let path = Bundle.main.path(forResource: baseName, ofType: fileExt) {
            
            // Particle effects are automatically archived when created
            // We need to un-archive the effect file so it can be treated as an SKEmitterNode object
            let node = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! SKEmitterNode
            
            return node
        }
        return nil
    }
    
    func pdc_dieOutInDuration(_ duration: TimeInterval) {
        
        // We want to add explosions to the two collisions involving photon vs obstacle
        // and ship vs obstacle. We dont want the emitters to keep running for explosions
        // we will make them die out after a short duration
        
        // Define two waiting periods because once we set the birthrate to 0, we will still
        // need to wait until the particles die out. Otherwise the particles will vanish from
        // the screen immediately
        
        let firstWait = SKAction.wait(forDuration: duration)
        
        // Set birthrate property to 0 in order to make the particle effect disappear using an 
        // SKAction code block
        let stop = SKAction.run{
            [weak self] in
            
            if let weakSelf = self {
                weakSelf.particleBirthRate = 0
            }
        }
        
        
        let secondWait = SKAction.wait(forDuration: TimeInterval(self.particleLifetime))
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence([firstWait, stop, secondWait, remove]))
        
        
    } // end of pdc_dieOutInDuration
   
}// end of extension





