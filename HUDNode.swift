//
//  HUDNode.swift
//  SpaceRun
//
//  Created by Jake Ellious on 4/29/16.
//  Copyright © 2016 Jake Ellious. All rights reserved.
//
import SpriteKit

class HUDNode: SKNode {
    

    fileprivate let ScoreGroupName = "scoreGroup"
    fileprivate let ScoreValueName = "scoreValue"
    
    fileprivate let HealthGroupName = "healthGroup"
    fileprivate let HealthValueName = "healthValue"
    
    fileprivate let ElapsedGroupName = "elapsedGroup"
    fileprivate let ElapsedValueName = "elapsedValue"
    fileprivate let TimerActionName = "elapsedGameTimer"
    
    var elapsedTime : TimeInterval = 0.0
    var score : Int = 0
    lazy fileprivate var scoreAndHealthFormatter : NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    lazy fileprivate var timeFormatter : NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    override init() {
        super.init()
        
        // Score
        let scoreGroup = SKNode()
        scoreGroup.name = ScoreGroupName
        
        // Score title setup
        let scoreTitle =  SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.fontSize = 12.0
        scoreTitle.fontColor = SKColor.white
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.verticalAlignmentMode = .bottom
        scoreTitle.text = "SCORE"
        // The child nodes are positioned relative to the parent node's origin point
        scoreTitle.position = CGPoint(x: 0.0, y: 4.0)
        
        scoreGroup.addChild(scoreTitle)
        
        // Score Value:
        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.fontSize = 20.0
        scoreValue.fontColor = SKColor.white
        scoreValue.horizontalAlignmentMode = .left
        scoreValue.verticalAlignmentMode = .top
        scoreValue.name = ScoreValueName
        scoreValue.text = "0"
        scoreValue.position = CGPoint(x: 0.0, y: -4.0)
        
        scoreGroup.addChild(scoreValue)
        
        // Add Score Group
        addChild(scoreGroup)
        
        // Health Title
        let healthGroup = SKNode()
        healthGroup.name = HealthGroupName
        
        let healthTitle =  SKLabelNode(fontNamed: "AvenirNext-Medium")
        healthTitle.fontSize = 20.0
        healthTitle.fontColor = SKColor.white
        healthTitle.horizontalAlignmentMode = .center
        healthTitle.verticalAlignmentMode = .bottom
        healthTitle.text = "HEALTH"
        healthTitle.position = CGPoint(x: 0.0, y: -8.0)
        
        healthGroup.addChild(healthTitle)
        
        // Health Value
        let healthValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        healthValue.fontSize = 25.0
        healthValue.fontColor = SKColor.white
        healthValue.horizontalAlignmentMode = .center
        healthValue.verticalAlignmentMode = .top
        healthValue.name = HealthValueName
        healthValue.text = "50"
        healthValue.position = CGPoint(x: 0.0, y: -12.0)
        
        healthGroup.addChild(healthValue)
        
        // Add Score Group
        addChild(healthGroup)
        
        
        // Elapsed Title
        let elapsedGroup = SKNode()
        elapsedGroup.name = ElapsedGroupName
        
        let elapsedTitle =  SKLabelNode(fontNamed: "AvenirNext-Medium")
        elapsedTitle.fontSize = 12.0
        elapsedTitle.fontColor = SKColor.white
        elapsedTitle.horizontalAlignmentMode = .right
        elapsedTitle.verticalAlignmentMode = .bottom
        elapsedTitle.text = "TIME"
        elapsedTitle.position = CGPoint(x: 0.0, y: 4.0)
        
        elapsedGroup.addChild(elapsedTitle)
        
        // Elapsed Value
        let elapsedValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        elapsedValue.fontSize = 20.0
        elapsedValue.fontColor = SKColor.white
        elapsedValue.horizontalAlignmentMode = .right
        elapsedValue.verticalAlignmentMode = .top
        elapsedValue.name = ElapsedValueName
        elapsedValue.text = "0.0s"
        elapsedValue.position = CGPoint(x: 0.0, y: -4.0)
        
        elapsedGroup.addChild(elapsedValue)
        
        // Add Elapsed Group
        addChild(elapsedGroup)
        
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // Layout
    
    // Our labels are properly layed out within their parent group nodes, but the group nodes are
    // centered on the screen. We need to create some layout method, so these group nodes are properly
    // positioned to the top left and top right corners when this HUDNode is added to the scene
    func layoutForScene() {
        if let scene = scene {
            let sceneSize = scene.size
            var groupSize = CGSize.zero // Used to calculate position of each group
            
            // Score
            if let scoreGroup = childNode(withName: ScoreGroupName) {
                groupSize = scoreGroup.calculateAccumulatedFrame().size // Get calculated size of our scoreGroup node
                scoreGroup.position = CGPoint(x: 0.0 - sceneSize.width/2.0 + 20.0, y: sceneSize.height/2.0 - groupSize.height)
            } else {
                assert(false, "No score node found.")
            }
            
            // Health
            if let healthGroup = childNode(withName: HealthGroupName) {
                groupSize = healthGroup.calculateAccumulatedFrame().size
                healthGroup.position = CGPoint(x: 0.0, y: sceneSize.height/2.0 - groupSize.height)
            } else {
                assert(false, "No healthPowerUp node found.")
            }
            
            // Elapsed Time
            if let elapsedGroup = childNode(withName: ElapsedGroupName) {
                groupSize = elapsedGroup.calculateAccumulatedFrame().size
                elapsedGroup.position = CGPoint(x: sceneSize.width/2.0 - 20.0, y: sceneSize.height/2.0 - groupSize.height)
            } else {
                assert(false, "No elapsed time node found.")
            }
        } else {
            assert(false, "Cannot be called unless added to a scene.")
        }
    }
    
    
    
    
    
    func startGame() {
        let startTime = Date.timeIntervalSinceReferenceDate
        if let elapsedValue = childNode(withName: "\(ElapsedGroupName)/\(ElapsedValueName)") as! SKLabelNode? {
            let update = SKAction.run({ [weak self] in
                if let weakSelf = self {
                    let now = Date.timeIntervalSinceReferenceDate
                    let elapsed = now - startTime
                    weakSelf.elapsedTime = elapsed
                    //elapsedValue.text = weakSelf.timeFormatter.string(from: NSNumber(elapsed))!
                }
                })
            let delay = SKAction.wait(forDuration: 0.05)
            let updateAndDelay = SKAction.sequence([update, delay])
            let timer = SKAction.repeatForever(updateAndDelay)
            run(timer, withKey: TimerActionName)
        }
    }

    
    
    func addPoints(_ points: Int) {
        score += points
        if let scoreValue = childNode(withName: "\(ScoreGroupName)/\(ScoreValueName)") as! SKLabelNode? {
            //scoreValue.text = scoreAndHealthFormatter.string(from: NSNumber(score))!
            
            let scale = SKAction.scale(to: 1.1, duration: 0.02)
            let shrink = SKAction.scale(to: 1.0, duration: 0.07)
            scoreValue.run(SKAction.sequence([scale, shrink]))
        }
    }    
    
    
    
    func updateHealth(_ health: Int){
        if let healthValue = childNode(withName: "\(HealthGroupName)/\(HealthValueName)") as! SKLabelNode? {
            //healthValue.text = scoreAndHealthFormatter.string(from: NSNumber(health))!
            let scale = SKAction.scale(to: 1.1, duration: 0.02)
            let shrink = SKAction.scale(to: 1.0, duration: 0.07)
            healthValue.run(SKAction.sequence([scale, shrink]))
        }
    }
    
    
    
    
    
    
    
}
