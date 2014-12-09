/**
 * Created by Rolf on 12/7/14.
 */
package game.controllers {
import citrus.objects.CitrusSprite;

import starling.core.Starling;

import starling.text.TextField;
import starling.textures.TextureSmoothing;

public class WaveManager {
    public function WaveManager() {
        TextField.getBitmapFont('font').smoothing = TextureSmoothing.NONE;

        _view = new TextField(
                100,
                100,
                'WAVE 1',
                'font',
                8*8,
                0xffffff
        );
        _display = new CitrusSprite('wave',{
            x:Starling.current.stage.stageWidth>>1,
            y:Starling.current.stage.stageHeight>>1,
            view:_view
        });
        index = 0;
    }
    private var _view:TextField;
    private var _display:CitrusSprite;

    public function get view():TextField {
        return _view;
    }
    public var index:int;
    public function setWave():void{
        _view.text = "WAVE "+index.toString();
    }

    public function get display():CitrusSprite {
        return _display;
    }
}
}
