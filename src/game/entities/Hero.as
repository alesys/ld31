/**
 * Created by Rolf on 12/5/14.
 */
package game.entities {
import citrus.objects.NapePhysicsObject;
import citrus.objects.platformer.nape.Hero;
import citrus.objects.platformer.nape.Platform;
import citrus.physics.nape.NapeUtils;

import nape.callbacks.InteractionCallback;
import nape.geom.Vec2;

import org.osflash.signals.Signal;

import starling.animation.Juggler;
import starling.display.MovieClip;
import starling.textures.TextureSmoothing;
import starling.utils.AssetManager;

public class Hero extends citrus.objects.platformer.nape.Hero {
    public function Hero(name:String, params:Object = null) {
        super(name, params);
        initViews();
    }

    private function initViews():void {
        view = views.idle;
        for (var viewname:String in views) {
            if(views[viewname] is MovieClip){
                var v:MovieClip;
                v = views[viewname];
                v.smoothing = TextureSmoothing.NONE;
                juggler.add(v);
            }
        }
    }

    public var juggler:Juggler;
    public var kickVelocity:int = 300;
    public var punchVelocity:int = 200;

    public var hp:int = 200;
    public var maxHP:int = 200;
    public var strenght:Number = 20;
    public var views:Object;
    public var assets:AssetManager;

    private var _direction:int = 1;

    private var _hitting:Boolean;

    public function get hitting():Boolean {
        return _hitting;
    }


    override public function update(timeDelta:Number):void {
        _timeDelta = timeDelta;

        // we get a reference to the actual velocity vector
        var velocity:Vec2 = _body.velocity;

        if (controlsEnabled) {
            var moveKeyPressed:Boolean = false;

            _ducking = (_ce.input.isDoing("down", inputChannel) && _onGround && canDuck);

            if (_ce.input.justDid('jump') && _onGround){
                assets.playSound('jump');
            }

            if (_ce.input.isDoing("right", inputChannel) && !_ducking) {
                //velocity.addeq(getSlopeBasedMoveAngle());
                if (velocity.x < 0)velocity.x = 0;
                velocity.x += acceleration;
                moveKeyPressed = true;
                _direction = 1;
            }

            if (_ce.input.isDoing("left", inputChannel) && !_ducking) {
                //velocity.subeq(getSlopeBasedMoveAngle());
                if (velocity.x > 0)velocity.x = 0;
                velocity.x -= acceleration;
                moveKeyPressed = true;
                _direction = -1;
            }

            //If player just started moving the hero this tick.
            if (moveKeyPressed && !_playerMovingHero) {
                _playerMovingHero = true;
                _material.dynamicFriction = 0; //Take away friction so he can accelerate.
                _material.staticFriction = 0;
            }
            //Player just stopped moving the hero this tick.
            else if (!moveKeyPressed && _playerMovingHero) {
                _playerMovingHero = false;
                _material.dynamicFriction = _dynamicFriction; //Add friction so that he stops running
                _material.staticFriction = _staticFriction;
            }

            if (_onGround && _ce.input.justDid("jump", inputChannel) && !_ducking) {
                velocity.y = -jumpHeight;
                onJump.dispatch();
                _onGround = false; // also removed in the handleEndContact. Useful here if permanent contact e.g. box on hero.
            }

            if (_ce.input.isDoing("jump", inputChannel) && !_onGround && velocity.y < 0) {
                velocity.y -= jumpAcceleration;
            }

            if (_springOffEnemy != -1) {
                if (_ce.input.isDoing("jump", inputChannel))
                    velocity.y = -enemySpringJumpHeight;
                else
                    velocity.y = -enemySpringHeight;
                _springOffEnemy = -1;
            }


            //Cap velocities
            if (velocity.x > (maxVelocity))
                velocity.x = maxVelocity;
            else if (velocity.x < (-maxVelocity))
                velocity.x = -maxVelocity;


            if (_ce.input.justDid("punch", inputChannel) && !_hurt && !_hitting) {
                trace('punch');
                _hitting = true;
                _controlsEnabled = false;
                _punch = true;
                trace('hero density and mass', _material.density, _body.mass);
                velocity.x = punchVelocity * _direction;
                _body.mass = _hittingMass;
                timerHitting(.2);
                assets.getSound('punch').play();

            }

            if (_ce.input.justDid("kick", inputChannel) && !_hurt && !_hitting) {
                trace('kick');
                _hitting = true;
                _controlsEnabled = false;
                _punch = false;
                _body.mass = _hittingMass;
                velocity.x = kickVelocity * _direction;
                timerHitting(.3);
                assets.getSound('kick').play();
            }
        }

        updateAnimation();
    }
    private var _originalMass:Number = 2.4;
    private var _hittingMass:Number = 30;

    private var _punch:Boolean;
    override protected function updateAnimation():void {
        var prevAnimation:String = _animation;

        //var walkingSpeed:Number = getWalkingSpeed();
        var walkingSpeed:Number = _body.velocity.x; // this won't work long term!

        if (_hurt && hp>0)
            _animation = "hurt";
        else if (_hurt && hp<=0){
            _animation = 'die';
        }
        else if (_hitting && _punch)
            _animation = "punch";
        else if (_hitting && !_punch)
            _animation = "kick";
        else if (!_onGround) {

            _animation = "jump";

            if (walkingSpeed < -acceleration)
                _inverted = true;
            else if (walkingSpeed > acceleration)
                _inverted = false;

        }
        else {

            if (walkingSpeed < -acceleration) {
                _inverted = true;
                _animation = "walk";

            } else if (walkingSpeed > acceleration) {

                _inverted = false;
                _animation = "walk";

            } else
                _animation = "idle";
        }

        if (prevAnimation != _animation){
            switch(_animation){
                case "idle":
                    view = views.idle;
                    break;
                case "walk":
                    view = views.walk;
                    break;
                case "kick":
                    view = views.kick;
                    (views.kick as MovieClip).currentFrame = 0;
                    break;
                case "punch":
                    view = views.punch;
                    (views.punch as MovieClip).currentFrame = 0;
                    break;
                case "jump":
                    view = views.jump;
                    break;
                case "hurt":
                    view = views.hurt;
                    break;
                case "die":
                    view = views.die;
                    (views.die as MovieClip).currentFrame = 0;
                    break;
            }
            onAnimationChange.dispatch();
        }
    }

    override public function handleBeginContact(callback:InteractionCallback):void {
        var collider:NapePhysicsObject = NapeUtils.CollisionGetOther(this, callback);

        if (_enemyClass && collider is Enemy) {
//            if ((_body.velocity.y == 0 || _body.velocity.y < killVelocity) && !_hurt)
//            {
//                hurt();
//
//                //fling the hero
//                var hurtVelocity:Vec2 = _body.velocity;
//                hurtVelocity.y = -hurtVelocityY;
//                hurtVelocity.x = hurtVelocityX;
//                if (collider.x > x)
//                    hurtVelocity.x = -hurtVelocityX;
//                _body.velocity = hurtVelocity;
//            }
//            else
//            {
//                _springOffEnemy = collider.y - height;
//                onGiveDamage.dispatch();
//            }

            if (_hitting) {

            } else {
                hurt();
                var hurtVelocity:Vec2 = _body.velocity;
                hurtVelocity.y = -hurtVelocityY;
                hurtVelocity.x = hurtVelocityX;
                if (collider.x > x)
                    hurtVelocity.x = -hurtVelocityX;
                _body.velocity = hurtVelocity;
                hp -= (collider as Enemy).strenght;
            }

        }

        if (callback.arbiters.length > 0 && callback.arbiters.at(0).collisionArbiter) {

            var collisionAngle:Number = callback.arbiters.at(0).collisionArbiter.normal.angle * 180 / Math.PI;

            if ((collisionAngle > 45 && collisionAngle < 135) || (collisionAngle > -30 && collisionAngle < 10) || collisionAngle == -90) {
                if (collisionAngle > 1 || collisionAngle < -1) {
                    //we don't want the Hero to be set up as onGround if it touches a cloud.
                    if (collider is Platform && (collider as Platform).oneWay && collisionAngle == -90)
                        return;

                    _groundContacts.push(collider.body);
                    _onGround = true;
                    //updateCombinedGroundAngle();
                }
            }
        }
    }

    private function timerHitting($_duration:Number):void {
        juggler.delayCall(enableHitting, $_duration);
    }

    private function enableHitting():void {
        _hitting = false;
        _controlsEnabled = true;
        _body.mass = _originalMass;
    }

    override public function hurt():void {
        super.hurt();
        assets.playSound('hurt');
        _body.group = Enemy.ENEMY_GROUP; // Enemies can touch the hero
    }

    override protected function endHurtState():void {
        if(hp>0){
            super.endHurtState();
            _body.group = null; // Enemies can touch the hero
        }
        else{
            assets.getSound('explosion').play();
            _died.dispatch();
        }
    }
    private var _died:Signal = new Signal();

    public function get died():Signal {
        return _died;
    }
}
}
