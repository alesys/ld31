package {

import citrus.core.starling.StarlingCitrusEngine;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import flash.geom.Rectangle;

import game.Game;

[SWF(frameRate="48",backgroundColor="0xc4cfa1",width="1280",height="720")]

public class Main extends StarlingCitrusEngine {
    public function Main() {

    }

    override public function initialize():void {
        super.initialize();
        setUpStarling(false,1,new Rectangle(
                0,
                0,
                stage.stageWidth,
                stage.stageHeight
        ));
    }

    override public function handleStarlingReady():void {
        super.handleStarlingReady();
        var g:Game = new Game();
        g.ended.add(listenKeyOrMouse);
        state = g;
    }

    private function listenKeyOrMouse():void {
        stage.addEventListener(KeyboardEvent.KEY_DOWN, handleReset);
        stage.addEventListener(MouseEvent.CLICK, handleReset);
    }
    private function handleReset(e:Event):void{
        stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleReset);
        stage.removeEventListener(MouseEvent.CLICK, handleReset);

//        var g:Game = new Game();
//        g.ended.addOnce(listenKeyOrMouse);
//        state = g;
        (state as Game).reset();
    }


    override protected function handleEnterFrame(e:Event):void {
        super.handleEnterFrame(e);
    }



}
}

