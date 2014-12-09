/**
 * Created by Rolf on 12/5/14.
 */
package game.entities {
import citrus.objects.NapePhysicsObject;
import citrus.objects.platformer.nape.Enemy;
import citrus.objects.platformer.nape.Platform;
import citrus.physics.nape.NapeUtils;

import nape.callbacks.InteractionCallback;
import nape.dynamics.InteractionGroup;
import nape.geom.Vec2;

import org.osflash.signals.Signal;

import starling.animation.Juggler;

import starling.display.MovieClip;

import starling.textures.TextureSmoothing;
import starling.utils.AssetManager;

public class Enemy extends citrus.objects.platformer.nape.Enemy {
    public static const ENEMY_GROUP:InteractionGroup = new InteractionGroup(true);

    public function Enemy(name:String, params:Object = null) {
        super(name, params);
        initViews();
    }

    public var hp:int = 200;
    public var maxHP:int = 200;
    public var strenght:Number = 20;
    public var assets:AssetManager;

    public var hurtVelocityX:Number = 480;
    public var hurtVelocityY:Number = 300;
    public var views:Object;
    public var juggler:Juggler;

    private var _removeMe:Boolean;


    public function get removeMe():Boolean {
        return _removeMe;
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
    override protected function createBody():void {
        super.createBody();
        _body.group = ENEMY_GROUP;
    }
    private var _died:Signal = new Signal();

    public function get died():Signal {
        return _died;
    }

    override protected function endHurtState():void {
        if(hp<=0){
//            _removeMe=true;
            _died.dispatch();
            kill = true;
        }else{
            _hurt = false;
        }

    }


    override public function handleBeginContact(callback:InteractionCallback):void {
        var collider:NapePhysicsObject = NapeUtils.CollisionGetOther(this, callback);

        if (callback.arbiters.length > 0 && callback.arbiters.at(0).collisionArbiter) {

            var collisionAngle:Number = callback.arbiters.at(0).collisionArbiter.normal.angle * 180 / Math.PI;

//            if (collider is _enemyClass && collider.body.velocity.y != 0 && collider.body.velocity.y > enemyKillVelocity)
//                hurt();
//            else if ((collider is Platform && collisionAngle != 90) || collider is game.entities.Enemy)
//                turnAround();

            if (collider is Hero) {
                var hero:Hero = collider as Hero;
                if (hero.hitting) {
                    // enemy is hurt
                    hurt();
                    var hurtVelocity:Vec2 = _body.velocity;
                    hurtVelocity.y = -hurtVelocityY;
                    hurtVelocity.x = hurtVelocityX;
                    if (collider.x > x)
                        hurtVelocity.x = -hurtVelocityX;
                    _body.velocity = hurtVelocity;
                    hp -= hero.strenght;
                    trace('enemy.hp',hp);
                }
            }
            else if (collider is Platform && collisionAngle != 90) {
                turnAround();
            }
        }
    }


    override public function update(timeDelta:Number):void {
        _timeDelta = timeDelta;

        var position:Vec2 = _body.position;

        //Turn around when they pass their left/right bounds
        if ((_inverted && position.x < leftBound) || (!_inverted && position.x > rightBound))
            turnAround();

        var velocity:Vec2 = _body.velocity;

        if (!_hurt)
            velocity.x = _inverted ? -speed : speed;

        updateAnimation();
    }


    override protected function updateAnimation():void {
        var prevAnimation:String = _animation;
        _animation = hp <=0 ? "die" : _hurt ? "hurt" : "walk";

        if(_animation==prevAnimation) return;
        switch(_animation){
            case 'walk':
                view = views.walk;
                break;
            case 'hurt':
                view = views.hurt;
                    assets.playSound('hurt');
                break;
            case 'die':
                view = views.die;
                view.currentFrame = 0;
                view.play();
                view.loop = false;
                    assets.playSound('explosion');
                break;
        }
    }

    override public function hurt():void {
        super.hurt();
    }
}
}
