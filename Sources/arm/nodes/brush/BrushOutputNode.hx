package arm.nodes.brush;

import arm.ui.UITrait;
import arm.ui.UIView2D;
import arm.Tool;

@:keep
class BrushOutputNode extends LogicNode {

	public function new(tree:LogicTree) {
		super(tree);
		UITrait.inst.notifyOnBrush(run);
	}

	override function run(from:Int) {
		UITrait.inst.paintVec = inputs[0].get();
		UITrait.inst.brushNodesRadius = inputs[1].get();
		UITrait.inst.brushNodesOpacity = inputs[2].get();
		UITrait.inst.brushNodesHardness = inputs[3].get();
		UITrait.inst.brushNodesScale = inputs[4].get();

		var left = 0;
		var right = 1;
		if (UITrait.inst.paint2d) {
			left = 1;
			right = 2;
		}

		// First time init
		if (UITrait.inst.lastPaintX < 0 || UITrait.inst.lastPaintY < 0) {
			UITrait.inst.lastPaintVecX = UITrait.inst.paintVec.x;
			UITrait.inst.lastPaintVecY = UITrait.inst.paintVec.y;
		}

		// Paint bounds
		if (UITrait.inst.paintVec.x < right && UITrait.inst.paintVec.x > left &&
			UITrait.inst.paintVec.y < 1 && UITrait.inst.paintVec.y > 0 &&
			!UITrait.inst.ui.isHovered &&
			!UITrait.inst.ui.isScrolling &&
			!arm.App.isDragging &&
			@:privateAccess UITrait.inst.ui.comboSelectedHandle == null &&
			@:privateAccess UIView2D.inst.ui.comboSelectedHandle == null) { // Header combos are in use
			// Set color pick
			var down = iron.system.Input.getMouse().down() || iron.system.Input.getPen().down();
			if (Context.tool == ToolColorId && Project.assets.length > 0 && down) {
				UITrait.inst.colorIdPicked = true;
			}
			// Prevent painting the same spot
			if (down && UITrait.inst.paintVec.x == UITrait.inst.lastPaintX && UITrait.inst.paintVec.y == UITrait.inst.lastPaintY) {
				UITrait.inst.painted++;
			}
			else {
				UITrait.inst.painted = 0;
			}
			UITrait.inst.lastPaintX = UITrait.inst.paintVec.x;
			UITrait.inst.lastPaintY = UITrait.inst.paintVec.y;

			if (Context.tool == ToolParticle) {
				UITrait.inst.painted = 0; // Always paint particles
			}

			var decal = Context.tool == ToolDecal || Context.tool == ToolText;
			var paintFrames = decal ? 1 : 4;

			if (UITrait.inst.painted <= paintFrames) {
				Context.pdirty = 1;
				Context.rdirty = 2;
			}
		}

		runOutput(0);
	}
}
