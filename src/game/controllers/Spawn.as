/**
 * Created by Rolf on 12/5/14.
 */
package game.controllers {

import org.osflash.signals.Signal;

import starling.animation.IAnimatable;
import starling.animation.Juggler;

public class Spawn {
    public function Spawn($_params:Object) {
        _params = $_params;
    }

    private var _params:Object;
    private var _repeatCall:IAnimatable;
    private var _duration:int;
    private var _count:int;

    private var _juggler:Juggler;

    public function set juggler(juggler:Juggler):void {
        _juggler = juggler;
    }

    private var _ticked:Signal = new Signal(Object);

    public function get ticked():Signal {
        return _ticked;
    }

    private var _ended:Signal = new Signal();

    public function get ended():Signal {
        return _ended;
    }

    public function start($_delay:Number = 1, $_duration:int = 10):void {
        _repeatCall = _juggler.repeatCall(tick, $_delay);
        _duration = $_duration;
        _count = 0;
    }

    public function stop():void {
        if (_repeatCall) {
            _juggler.remove(_repeatCall);
            _repeatCall = null;
        }
    }

    private function tick():void {
        _ticked.dispatch(_params);
        if (++_count == _duration) {
            stop();
            _ended.dispatch();
        }
    }
}
}
