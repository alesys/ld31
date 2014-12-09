/**
 * Created by Rolf on 12/5/14.
 */
package game {
import citrus.core.CitrusObject;
import citrus.core.starling.StarlingState;
import citrus.input.controllers.Keyboard;
import citrus.objects.CitrusSprite;
import citrus.objects.platformer.nape.Platform;
import citrus.physics.nape.Nape;

import game.controllers.Spawn;
import game.controllers.WaveManager;
import game.entities.Enemy;
import game.entities.Hero;
import game.entities.Ninja;

import org.osflash.signals.Signal;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.display.Image;
import starling.display.MovieClip;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.textures.TextureSmoothing;
import starling.utils.AssetManager;

public class Game extends StarlingState {
    private const PATH:String = '';
    public function Game() {
        super();
        _juggler = new Juggler();

    }

    override public function initialize():void {
        super.initialize();
        loadAssets();
    }
    private var _assets:AssetManager;
    private function loadAssets():void {
        _assets = new AssetManager(.125,false);
        _assets.enqueue('levels.json');
        _assets.enqueue('sprites.png');
        _assets.enqueue('sprites.xml');
        _assets.enqueue('font.fnt');
        _assets.enqueue('end.mp3');
        _assets.enqueue('explosion.mp3');
        _assets.enqueue('hurt.mp3');
        _assets.enqueue('jump.mp3');
        _assets.enqueue('kick.mp3');
        _assets.enqueue('punch.mp3');
        _assets.enqueue('wave.mp3');
        _assets.loadQueue(function(r:Number):void{
            if(r==1)onLoadAssets();
        })
    }

    private function onLoadAssets():void {
        setupPhysics();
        addInputs();

        parse(_assets.getObject('levels')[0]);
        setupTitles();
        startWave(5,2);

    }

    private function setupTitles():void {
        TextField.getBitmapFont('font').smoothing = TextureSmoothing.NONE;
        waveTitle = new TextField(100,100,'WAVE 0','font',8*8,0xffffff);
        waveTitle.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;

        gameOverTitle = new TextField(100,100,'GAME OVER','font',8*8,0xffffff);
        gameOverTitle.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
    }

    private function showGameOver():void{
        gameOverTitle.alignPivot();
        gameOverTitle.x = stage.stageWidth>>1;
        gameOverTitle.y = -gameOverTitle.height;
        addChild(gameOverTitle);
        _juggler.tween(gameOverTitle,1,{y:stage.stageHeight>>1,transition:Transitions.EASE_OUT_BACK});
        _assets.playSound('end');
    }

    private var _waves:int=1;
    private var waveTitle:TextField;
    private var gameOverTitle:TextField;
    private var _ended:Signal = new Signal();
    public function get ended():Signal {
        return _ended;
    }

    public function showWaveTitle():void{
        waveTitle.text = 'WAVE ' + _waves;
        waveTitle.alignPivot();
        waveTitle.x = stage.stageWidth>>1;
        waveTitle.y = stage.stageHeight>>1;
        addChild(waveTitle);
        _juggler.tween(waveTitle,1,{y:-waveTitle.height,transition:Transitions.EASE_IN_BACK,delay:3});
        _assets.playSound('wave');
    }
    private function setupPhysics():void {
        var nape:Nape = new Nape('nape');
//        nape.visible = true;
        add(nape);
    }
    private function parse(object:Object):void {
        var _platforms:Array = object.platforms;
        var _triggers:Array = object.triggers;
        var _tiles:Array = object.tiles;
        parseTiles(_tiles);
        parsePlatforms(_platforms);
        parseTriggers(_triggers);
    }

    private function parseTiles(_tiles:Array):void {
        for (var i:int = 0; i < _tiles.length; i++) {
            var data:Object = _tiles[i];
            var sprite:CitrusSprite;
            var tile:Image;
            tile = new Image(_assets.getTexture(data.name));
            tile.smoothing = TextureSmoothing.NONE;
            sprite = new CitrusSprite(
                    'tile',
                    {
                        x:data.x,
                        y:data.y,
                        view:tile
                    }
            );
            add(sprite);
        }
    }

    private function addInputs():void {
        _ce.input.keyboard.addKeyAction('punch',Keyboard.A);
        _ce.input.keyboard.addKeyAction('kick',Keyboard.S);
    }

    private function parseTriggers(_triggers:Array):void {
        /**
         * "x": 60,
         "value": "",
         "width": 40,
         "type": "hero",
         "height": 60,
         "y": 650
         */
        spawnSpots = new Vector.<Spawn>();
        for (var i:int = 0; i < _triggers.length; i++) {
            var data:Object = _triggers[i];
            switch(data.type){
                case 'hero':
                    var hero:Hero;
                    hero = new Hero('hero',{
                        x:data.x,
                        y:data.y,
                        width:data.width,
                        height:data.height,
                        juggler:_juggler,
                        hurtDuration: 300,
                        jumpHeight:330 * .8,
                        hp:200,
                        maxHP:200,
                        strenght: 20,
                        maxVelocity: 180,
                        hurtVelocityX: 300,
                        kickVelocity: 120,
                        punchVelocity: 80,
                        canDuck: false,
                        assets:_assets,
                        views:{
                            idle: new MovieClip(_assets.getTextures('idle'),1),
                            walk: new MovieClip(_assets.getTextures('walk'),6),
                            kick: new MovieClip(_assets.getTextures('kick'),6),
                            punch: new MovieClip(_assets.getTextures('punch'),6),
                            jump: new MovieClip(_assets.getTextures('jump'),6),
                            hurt: new MovieClip(_assets.getTextures('hurt'),6),
                            die: new MovieClip(_assets.getTextures('xplo'),6)
                        }
                    });
                    (hero.views.kick as MovieClip).loop = false;
                    (hero.views.punch as MovieClip).loop = false;
                    (hero.views.die as MovieClip).loop = false;
                    add(hero);
                        hero.died.add(heroDied);
                    break;
                case 'spawn':
                    var spawn:Spawn;

                    spawn = new Spawn(data);
                    spawn.juggler = _juggler;
                    spawn.ticked.add(handleSpawnEnemy);
                    spawnSpots.push(spawn);
                    break;
            }
        }
    }

    private function heroDied():void {
        showGameOver();
        _juggler.delayCall(function():void{
            _ended.dispatch();
        },2);
    }
    private var spawnSpots:Vector.<Spawn>;

    /**
     *
     * @param $_delay seconds
     * @param $_duration number of spawns
     */
    private function startWave($_delay:Number, $_duration:int):void{
        _totalEnemies = $_duration * spawnSpots.length;
        for (var i:int = 0; i < spawnSpots.length; i++) {
            var spawn:Spawn = spawnSpots[i];
            spawn.start($_delay,$_duration);
        }
        showWaveTitle();
    }
    private function enemyDied():void{
        _totalEnemies--;
        if(_totalEnemies==0){
            waveEnded();
        }
    }

    private function waveEnded():void {
        _waves++;
        startWave(3,_waves * 2);
    }
    private var _totalEnemies:int;
    private function handleSpawnEnemy($_data:Object):void {
        var enemy:Ninja;
        enemy = new Ninja('ninja',{
            x:$_data.x,
            y:$_data.y,
            width:$_data.width,
            height:$_data.height,
            speed: 58.1 * 2,
            hp:60,
            maxHP:60,
            strenght: 20,
            juggler:_juggler,
            assets:_assets,
            startingDirection:$_data.value,
            views:{
                walk: new MovieClip(_assets.getTextures('ninja_walk'),6),
                hurt: new MovieClip(_assets.getTextures('ninja_hurt'),6),
                die: new MovieClip(_assets.getTextures('xplo'),6)
            }

        });
        enemy.died.add(enemyDied);
        trace('die num frames',MovieClip(enemy.views.die).numFrames);
        add(enemy);
    }


    private function parsePlatforms(_platforms:Array):void {
        for (var i:int = 0; i < _platforms.length; i++) {
            var data:Object = _platforms[i];
            var platform:Platform;
            platform = new Platform('plat',{
                x:data.x,
                y:data.y,
                width:data.width,
                height:data.height
            });
//            platform.oneWay = 'cloud' == data.type;
            add(platform);
        }
    }
    private var _juggler:Juggler;
    override public function update(timeDelta:Number):void {
//        checkFlaggedObjects();
        super.update(timeDelta);
        _juggler.advanceTime(timeDelta);
    }

    private var removableObjects:Vector.<CitrusObject> = new Vector.<CitrusObject>();
    private function checkFlaggedObjects():void {
        for (var i:int = 0; i < objects.length; i++) {
            var citrusObject:CitrusObject = objects[i];
            if(citrusObject is Enemy){
                if ((citrusObject as Enemy).removeMe){
                    removableObjects.push(citrusObject);
                }
            }
        }
        if(removableObjects.length>0)
            removeObjects();
    }

    private function removeObjects():void {
        trace('removing',removableObjects.length,'objects');
        for (var i:int = 0; i < removableObjects.length; i++) {
            var citrusObject:CitrusObject = removableObjects[i];
            remove(citrusObject);
        }
        removableObjects.length = 0;
    }

    public function reset():void {
        clearObjects();
//        removeChildren();
        gameOverTitle.removeFromParent(true);
//        parse(_assets.getObject('levels')[0]);
        /**
         * var _platforms:Array = object.platforms;
         var _triggers:Array = object.triggers;
         var _tiles:Array = object.tiles;
         parseTiles(_tiles);
         parsePlatforms(_platforms);
         parseTriggers(_triggers);
         */
        parseTriggers(_assets.getObject('levels')[0].triggers);
        setupTitles();
        _waves=1;
        startWave(5,2);
    }

    private function clearObjects():void {
        for (var i:int = 0; i < objects.length; i++) {
            var citrusObject:CitrusObject = objects[i];
            if(citrusObject is Enemy || citrusObject is Hero){
//                if ((citrusObject as Enemy).removeMe){
//                    removableObjects.push(citrusObject);
//                }
                removableObjects.push(citrusObject);
            }
        }
        if(removableObjects.length>0)
            removeObjects();
    }
}
}
