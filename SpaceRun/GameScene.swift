//
//  GameScene.swift
//  SpaceRun
//
//  Created by Jake Ellious on 4/18/16.
//  Copyright (c) 2016 Jake Ellious. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    // Class properties
    // Assigning name dynamically so if we wanted to change it, we could from one centralized location
    fileprivate let SpaceShipNodeName = "ship" // Name of ship
    fileprivate let PhotonTorpedoNodeName = "photon" // Name of torpedo
    fileprivate let ObstacleNodeName = "obstacle" // Name of obstacle
    fileprivate let PowerUpNodeName = "powerup" // Name of powerUp
    fileprivate let HealthPowerUpNodeName = "healthPowerUp" // Name of healthPowerUp
    fileprivate var shipHealthNodeName = 50 // Initialize with 100 Health Points
    fileprivate let HUDNodeName = "hud" // Name of HUD
    
    // Properties to define sound actions
    // We will be be preloading our sounds into these properties
    fileprivate let shootSound:SKAction = SKAction.playSoundFileNamed("laserShot.wav", waitForCompletion: false)
    fileprivate let obstacleExplodeSound:SKAction = SKAction.playSoundFileNamed("darkExplosion.wav", waitForCompletion: false)
    fileprivate let shipExplodeSound:SKAction = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
    
    fileprivate weak var ShipTouch: UITouch?
    fileprivate var lastUpdateTime: TimeInterval = 0
    fileprivate var lastShotFiredTime: TimeInterval = 0
    
    // Properties to define powerUps
    fileprivate let defaultFireRate: Double = 0.5
    fileprivate var shipFireRate: Double = 0.5
    fileprivate let powerUpDuration: TimeInterval = 5.0 // 5 second duration
    
    // We will be using the particle emitters for our explosions repeatedly
    // We don't want to load them from their files every time, so instead
    // we will create class properties and cache them for quick reuse
    // Very much like we did for our sound related properties
    fileprivate let shipExplodeTemplate: SKEmitterNode = SKEmitterNode.pdc_nodeWithFile("shipExplode.sks")!
    fileprivate let obstacleExplodeTemplate: SKEmitterNode = SKEmitterNode.pdc_nodeWithFile("obstacleExplode.sks")!

    override init(size: CGSize){
        super.init(size: size)
        
        setupGame(size)
    }

    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
        setupGame(self.size)
    }
    
    
    
    // Function to setup game
    func setupGame(_ size: CGSize){
        
        // Creating Spaceship sprite
        let ship = SKSpriteNode(imageNamed: "Spaceship.png")
        ship.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        
        // Sizing ship
        ship.size = CGSize(width: 40.0, height: 40)
        
        // Setting name for SpriteKit to use as a reference, from our class property, similar to the DOM in web programming
        ship.name = SpaceShipNodeName
        
        // Adding ship to scene
        addChild(ship)
        
        // Adding starfield to scene by creating an instance of our starField class and adding it as a child to the scene
        addChild(StarField())
        
        // Adding ship particle thruster effect as a child
        if let shipThruster = SKEmitterNode.pdc_nodeWithFile("thrust.sks") {
            shipThruster.position = CGPoint(x: 0.0, y: -22.0)
            ship.addChild(shipThruster)
        }
        
        
        // HUD:
        let hudNode = HUDNode() // Instatiating our HUDNode class
        hudNode.name = HUDNodeName
        hudNode.zPosition = 100.0
        hudNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(hudNode)
        hudNode.layoutForScene()
        hudNode.startGame()
   
    }
    
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.fontSize = 45
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
        self.addChild(myLabel)
 */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            
            self.ShipTouch = touch
            
        }// end of if touch loop
        
    } // end of function touches began
    
    
    
   
    override func update(_ currentTime: TimeInterval) {
        
        // Creating delta to keep track of time difference
        let timeDelta = currentTime - lastUpdateTime
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        //calculate the time change(delta) since last frame
            if let shipTouch = self.ShipTouch{
            
                // Use the gamescenes childwithnodename method to re-obtain
                // a reference to our ship using its name property value from
                // the SpriteKits scene graph (node family tree)
                /*if let ship = self.childNodeWithName(SpaceShipNodeName){
                    ship.position = shipTouch.locationInNode(self)
            
            }*/ // end of ship position
                
                moveShipTowardPoint(shipTouch.location(in: self), timeChange: timeDelta)
                
                // We only want photon torpedos to launch from our ship when the users finger is in contact with the screen AND
                // if the difference between currenty time and last time a torpedo was fired is greater than .5 seconds
                if currentTime - lastShotFiredTime > shipFireRate {
                    shoot() // Fire a photon torpedo
                    
                    lastShotFiredTime = currentTime
                }
        } // end of shipTouch
        
        
        
        // Release astroid obstacles 1.5% of the time a frame is drawn
        // This number could be altered to increase or decrease game difficulty
        if arc4random_uniform(1000) <= 15 {
            dropThing()
        }
        
        
        checkCollisions()
        
        // Update lastUpdateTime to current time
        lastUpdateTime = currentTime
        
    } // end of update func
    
    
    // Nudge the ship toward the touch point (CGPoint) by an appropriate amount based on elapsed time (timeDelta) since our last frame
    func moveShipTowardPoint(_ point: CGPoint, timeChange: TimeInterval) {
        let shipSpeed = CGFloat(300)
        if let ship = self.childNode(withName: SpaceShipNodeName){
            
            // Using the Pythagorean Theorem, determine the distance between the ships current position and the touch point
            let distanctLeftToTravel = sqrt(pow(ship.position.x - point.x, 2) + pow(ship.position.y - point.y, 2))
            
            // If the distance left to travel is more than 4 points, keep moving the ship,
            // Otherwise stop because we may experience "jitters" if we get too close
            
            if distanctLeftToTravel > 5 {
                
                //Calculate how far we should move the ship during this frame
                let howFarToMove = CGFloat(timeChange) * shipSpeed
                
                // Convert the distance remaining back into (x, y) coordinates using the atan2() function
                // to determine the proper angle based on ships position and destination
                let angle = atan2(point.y - ship.position.y, point.x - ship.position.x)
                
                // Then, using the angle with the sine and cosine trig functions
                // determine the x and y offset values
                let xOffset = howFarToMove * cos(angle)
                let yOffset = howFarToMove * sin(angle)
                
                // Use the offsets to reposition the ship
                ship.position = CGPoint(x: ship.position.x + xOffset , y: ship.position.y + yOffset)
            }
        }
    } // end of moveShipTowardPoint
    
    
    
    
    //Shoot a photon torpedo from our ship
    func shoot(){
        if let ship = self.childNode(withName: SpaceShipNodeName){ // reference to ship node
            
            let photon = SKSpriteNode(imageNamed: "photon") // assigning "photon" image to new node
            
            photon.name = PhotonTorpedoNodeName // Giving photon a reference name
            
            photon.position = ship.position // Setting position of photon to same position of ship, to appear as if it comes out of the ship
            
            
            // add photon to scene
            self.addChild(photon)
            
            //Create a sequence of actions (SKAction class) that will move the torpedos
            // Up and off the top of the screen and then remove them so they dont take up memory
            
            // Move torpedo from its orginal position (ship position) past the top edge of the scene/screen
            // by the size of the photon over half a second. The Y axis in SpriteKit is flipped back to normal.
            // (0,0) is the bottom left corner. and scene height (self.size.height) is the top edge of the screen.
            
            let fly = SKAction.moveBy(x: 0, y: self.size.height + photon.size.height, duration: 0.5)
            
            // Run the created fly action
            //photon.runAction(fly)
            let remove = SKAction.removeFromParent()
            
            // Set up an SKAction sequence
            let fireAndRemove = SKAction.sequence([fly, remove])
            
            // Run action on the sequence
            photon.run(fireAndRemove)
            
            // Play shoot sound
            self.run(self.shootSound)
    }
}
    
    
    
    // Dropping nodes into game scene
    func dropThing(){
        
        let dieRoll = arc4random_uniform(100) // Value between 0-99
        
        if dieRoll < 3 {
            dropHealthPowerUp()
        }
        else if dieRoll < 15 {
            dropWeaponPowerUp()
        }
        else if dieRoll < 30 {
            dropEnemyShip()
        }
        else{
            dropAsteroid()
        }
    }
    
    
    
    
    func dropAsteroid(){
        // Define asteroid size - will be a random number between 15-44
        let sideSize = Double(arc4random_uniform(30) + 5)
        
        // Maximum X value for the scene
        let maxX = Double(self.size.width)
        
        let quarterX = maxX / 4.0
        
        // Max x + 50%
        let randRange = UInt32(maxX + (quarterX * 2))
        
        // arc4random_uniform() wants an UInt32 passed to it..
        
        // Determine a random starting value for asteroids X position (horizontal)
        let startX = Double(arc4random_uniform(randRange)) - quarterX
        
        // Determine starting point, at the top adding size of asteroid so it is off screen to start
        let startY = Double(self.size.height) + sideSize
        
        // Cast maxX to UInt32 to use with arc4random to determine the x point in which object ends
        let endX = Double(arc4random_uniform(UInt32(maxX)))
        
        // Ending y position. below bottom edge
        let endY = 0.0 - sideSize
        
        // Create asteroid sprite
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        asteroid.size = CGSize(width: sideSize, height: sideSize)
        asteroid.position = CGPoint(x: startX, y: startY)
        asteroid.name = ObstacleNodeName
        
        self.addChild(asteroid)
        
        // Run actions to get asteroids moving
        // Move asteroid to a randomly generated point over a duration of between 3 and 6 seconds
        let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: Double(arc4random_uniform(2) + 3))
        
        // Set up remove action
        let remove = SKAction.removeFromParent()
        
        // Set up sequence of actions
        let travelAndRemove = SKAction.sequence([move, remove])
        
        // Rotate the asteroid by 3 radians (just less than 180 degrees)
        // Do this over 1-3 seconds
        let spin = SKAction.rotate(byAngle: 3, duration:Double(arc4random_uniform(3) + 1))
        
        let spinForever = SKAction.repeatForever(spin)
        
        // Combine travelAndRemove & spinForever
        let allActions = SKAction.group([travelAndRemove, spinForever])
        
        // Run group on asteroid sprite
        asteroid.run(allActions)
    }
    
    
    
    
    // function defining dropping an enemy ship
    func dropEnemyShip(){
        
        let sideSize = 30.0
        
        // Determine a random starting value for enemyShip X position (horizontal)
        let startX = Double(arc4random_uniform(uint(self.size.width - 40)) + 20)
        
        // Determine starting point, at the top adding size of enemyShip so it is off screen to start
        let startY = Double(self.size.height) + sideSize
        
        // Create enemy ship and set its properties
        let enemy = SKSpriteNode(imageNamed: "enemy")
        
        enemy.size = CGSize(width:sideSize, height:sideSize)
        enemy.position = CGPoint(x: startX, y: startY)
        enemy.name = ObstacleNodeName // adding it to obstacle list for hit detection
        
        self.addChild(enemy)
        
        // Setup enemy movement
        //
        // We want the enemy ship to follow a curved (Bezier) path
        // which uses control points to determine how the curved path
        // is formed
        // The following method will return that path
        let shipPath = buildEnemyShipMovementPath()
        
        // Use the provided path to move our enemy ship
        // 
        // asOffset parameter: if set to true, lets us treat the actual point values
        // of the path as offsets from the enemy ship's starting point
        // A false value would treat the path's points as absolute positions
        // on the screen
        
        // orientToPath: if set to true, causes the enemy ship to turn and face
        // the direction of the path automatically
        
        let followPath = SKAction.follow(shipPath, asOffset: true, orientToPath: true, duration: 7.0)
        
        let remove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([followPath, remove]))
    }
    
    
    
    func buildEnemyShipMovementPath() -> CGPath{
        
        let yMax = -1.0 * self.size.height
        //Bezier path produced by using PaintCode app (www.paintcode.com)
        
        // Use the UIBezierPath class to build an object that adds the points
        // with 2 control points per point to construct a path
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: 0.5, y: -0.5))
        
        bezierPath.addCurve(to: CGPoint(x: -2.5, y: -59.5), controlPoint1: CGPoint(x: 0.5, y: -0.5), controlPoint2: CGPoint(x: 4.55, y: -29.48))
        
        bezierPath.addCurve(to: CGPoint(x: -27.5, y: -154.5), controlPoint1: CGPoint(x: -9.55, y: -89.52), controlPoint2: CGPoint(x: -43.32, y: -115.43))
        
        bezierPath.addCurve(to: CGPoint(x: 30.5, y: -243.5), controlPoint1: CGPoint(x: -11.68, y: -193.57), controlPoint2: CGPoint(x: 17.28, y: -186.95))
        
        bezierPath.addCurve(to: CGPoint(x: -52.5, y: -379.5), controlPoint1: CGPoint(x: 43.72, y: -300.05), controlPoint2: CGPoint(x: -47.71, y: -335.76))
        
        bezierPath.addCurve(to: CGPoint(x: 54.5, y: -449.5), controlPoint1: CGPoint(x: -57.29, y: -423.24), controlPoint2: CGPoint(x: -8.14, y: -482.45))
        
        bezierPath.addCurve(to: CGPoint(x: -5.5, y: -348.5), controlPoint1: CGPoint(x: 117.14, y: -416.55), controlPoint2: CGPoint(x: 52.25, y: -308.62))
        
        bezierPath.addCurve(to: CGPoint(x: 10.5, y: -494.5), controlPoint1: CGPoint(x: -63.25, y: -388.38), controlPoint2: CGPoint(x: -14.48, y: -457.43))
        
        bezierPath.addCurve(to: CGPoint(x: 0.5, y: -559.5), controlPoint1: CGPoint(x: 23.74, y: -514.16), controlPoint2: CGPoint(x: 6.93, y: -537.57))
        
        //bezierPath.addCurveToPoint(CGPointMake(-2.5, -644.5), controlPoint1: CGPointMake(-5.2, -578.93), controlPoint2: CGPointMake(-2.5, -644.5))
        
        bezierPath.addCurve(to: CGPoint(x: -2.5, y: yMax), controlPoint1: CGPoint(x: -5.2, y: yMax), controlPoint2: CGPoint(x: -2.5, y: yMax))
        
        return bezierPath.cgPath
    }
    
    
    
    func dropWeaponPowerUp(){
        
        // Create a powerUp sprite which spins and moves from top to bottom of screen
        
        let sideSize = 30.0
        
        // Determine a random starting value for powerups X position (horizontal)
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // Determine starting point, at the top adding size of powerUp so it is off screen to start
        let startY = Double(self.size.height) + sideSize
        
        let endY = 0 - sideSize
        
        // Create powerup and set its properties
        let powerUp = SKSpriteNode(imageNamed: "powerup")
        
        powerUp.size = CGSize(width:sideSize, height:sideSize)
        powerUp.position = CGPoint(x: startX, y: startY)
        powerUp.name = PowerUpNodeName // adding it to powerUp list for hit detection
        
        self.addChild(powerUp)
        
        let move = SKAction.move(to: CGPoint(x: startX, y: endY), duration: 6)
        
        let remove = SKAction.removeFromParent()
        
        let travelAndRemove = SKAction.sequence([move, remove])
        
        let spinForever = SKAction.repeatForever(SKAction.rotate(byAngle: 1, duration: 1))
        
        powerUp.run(SKAction.group([travelAndRemove, spinForever]))
    }
    
    
    func dropHealthPowerUp(){
        // Create a healthPowerowerUp sprite which spins and moves from top to bottom of screen
        
        // Set node size
        let sideSize = 20.0
        
        // Determine a random starting value for healthPowerups X position (horizontal)
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // Determine starting point, at the top adding size of healthPowerUp so it is off screen to start
        let startY = Double(self.size.height) + sideSize
        
        // Set ending Y point
        let endY = 0 - sideSize
        
        // Create healthPowerup and set its properties
        let powerUp = SKSpriteNode(imageNamed: "healthPowerUp")
        
        powerUp.size = CGSize(width:sideSize, height:sideSize)
        powerUp.position = CGPoint(x: startX, y: startY)
        powerUp.name = HealthPowerUpNodeName // adding it to healthPowerUp list for hit detection
        
        self.addChild(powerUp)
        
        let move = SKAction.move(to: CGPoint(x: startX, y: endY), duration: 5)
        
        let remove = SKAction.removeFromParent()
        
        let travelAndRemove = SKAction.sequence([move, remove])
        
        let spinForever = SKAction.repeatForever(SKAction.rotate(byAngle: 1, duration: 1))
        
        powerUp.run(SKAction.group([travelAndRemove, spinForever]))
    }
    
    
    
    // Implement a collision detection, by looping over all the nodes involved potentially in the 
    // collision in the scene graph node tree. Checking if their frames intersect.
    func checkCollisions(){
        if let ship = self.childNode(withName: SpaceShipNodeName){
        
            
            // PowerUp hit detection
            enumerateChildNodes(withName: PowerUpNodeName){
                powerUp, _ in
                
                if ship.intersects(powerUp){
                 
                    powerUp.removeFromParent()
                    
                    // Increase the ships fireRate
                    self.shipFireRate = 0.1
                    
                    // We need to power back down after a delay
                    // so we are not unbeatable
                    let powerDown = SKAction.run{
                        self.shipFireRate = self.defaultFireRate
                    }
                    
                    // Now lets set up a delay of 5 seconds before
                    // this powerup powers down
                    let wait = SKAction.wait(forDuration: self.powerUpDuration)
                    let waitAndPowerDown = SKAction.sequence([wait, powerDown])
                    
                    
                    //ship.runAction(waitAndPowerDown)
                    
                    // ok, if our ship collides with another power up while a powerup
                    // is already in progress, we dont get the benefit of a full reset
                    // why?
                    
                    // The first power up run block will run and restore the normal
                    // rate of fire too soon
                    
                    
                    // Sprite kit lets us run actions with a descriptive key
                    // that we can use to identify and remove the action before
                    // they've had a chance to run or finish
                    //
                    // If no key has been found, nothing changes...
                    let powerDownActionKey = "waitAndPowerDown"
                    
                    ship.removeAction(forKey: powerDownActionKey)
                    
                    ship.run(waitAndPowerDown, withKey: powerDownActionKey)
                }
            }
            
            
            // healthPowerUp hit detection
            enumerateChildNodes(withName: HealthPowerUpNodeName){
                healthPowerUp, _ in
                
                if ship.intersects(healthPowerUp){

                    healthPowerUp.removeFromParent()

                    // Increase the ships health if not already 100
                    if self.shipHealthNodeName < 100{
                        self.shipHealthNodeName = 100
                        // Update our health on our HUD
                        if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                            let hp = self.shipHealthNodeName
                            hud.updateHealth(hp)
                        }
                    }
                }
            }
            
            
            
            // This method will execute its code block for every node in the scene graph tree
            // that is an obstace node.
            //
            // This method will automatically populate the local identifier obstace with a 
            // reference to each (next) "obstace" node it found as it goes thru the tree
            enumerateChildNodes(withName: ObstacleNodeName){
                obstacle, _ in
                
                // Check for collision between our obstacle and the ship
                if (ship.intersects(obstacle)){
                    
                    
                    // Show explosion of obstacle against ship
                    let explosion = self.obstacleExplodeTemplate.copy() as! SKEmitterNode
                    explosion.position = ship.position
                    explosion.pdc_dieOutInDuration(0.1)
                    self.addChild(explosion)
                    
                    // Run obstacle explosion sound
                    self.run(self.obstacleExplodeSound)
                    
                    // Remove obstacle from scene
                    obstacle.removeFromParent()
                    
                    // Decrement health from our global constant
                    self.shipHealthNodeName -= 25
                    
                    // Update our health on our HUD
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        let hp = self.shipHealthNodeName
                        hud.updateHealth(hp)
                    }
                    
                 
                    
                    // If health goes below 0, end game and display end explosion
                    if self.shipHealthNodeName <= 0{
                        
                        // Set ship touch property to nil, so it will not be used
                        // by our shooting logic in the update() method to
                        // continue to track the touch and shoot photon torpedos
                        // If this doesnt work, the torpedos will be shot up from (0,0)
                        self.ShipTouch = nil
                        
                        // Remove ship and obstacle
                        ship.removeFromParent()
                        obstacle.removeFromParent()
                        
                        // Run ship explosion sound
                        self.run(self.shipExplodeSound)
                        
                        // Run shipExplode.sks
                        // Call copy on the shipExplodeTemplate node because nodes can
                        // only be added to a scene once.
                        // If we try to add a node that already exists in a scene, the
                        // game will crash with error... bad.
                        //
                        // We must use copies of particle emitter nodes and we will use
                        // the emitter node in our cached class property as a template
                        // from which to make these copies
                        let explosion = self.shipExplodeTemplate.copy() as! SKEmitterNode
                        
                        explosion.position = ship.position
                        explosion.pdc_dieOutInDuration(0.3)
                        self.addChild(explosion)
                    }
                }// end of intersect check
                
                
                //
                // INNER LOOP
                //
                
                
                // Add an inner loop inside our check for ship v. obstacle collisions
                // to check if any of our photon torpedos collide with obstacles
                self.enumerateChildNodes(withName: self.PhotonTorpedoNodeName){
                    myPhoton, stop in
                    
                    if myPhoton.intersects(obstacle){
                        
                        myPhoton.removeFromParent()
                        obstacle.removeFromParent()
                        
                        // Increment score
                        if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                            let score = 10 * Int(hud.elapsedTime)
                            hud.addPoints(score)
                        }
                        
                        // Run obstacle explosion sound
                        self.run(self.obstacleExplodeSound)
                        
                        // Run obstacleExplode.sks
                        let explosion = self.obstacleExplodeTemplate.copy() as! SKEmitterNode
                        
                        explosion.position = obstacle.position
                        explosion.pdc_dieOutInDuration(0.1)
                        self.addChild(explosion)
                        
                        // Set stop.memory to true to end this inner loop
                        // This is a lot like a break statement in other
                        // languages
                        stop.pointee = true
                    }
                }
            }// end of enumeration of nodes
        }
    }// end of checkCollisions()
    

}// end of class



