package arm.io;

import kha.Image;
import kha.Blob;
import kha.graphics4.TextureFormat;
import kha.arrays.Float32Array;
import iron.data.Data;
import iron.Scene;
import arm.ui.UITrait;
using StringTools;

class ImportEnvmap {

	public static function run(path:String, image:Image) {
		#if kha_krom
		var dataPath = Data.dataPath;
		var p = Krom.getFilesLocation() + '/' + dataPath;
		#if krom_windows
		var cmft = p + "/cmft.exe";
		#elseif krom_linux
		var cmft = p + "/cmft-linux64";
		#else
		var cmft = p + "/cmft-osx";
		#end

		var cmd = '';
		var tmp = Krom.getFilesLocation() + '/' + dataPath;

		// Irr
		cmd = cmft;
		cmd += ' --input "' + path + '"';
		cmd += ' --filter shcoeffs';
		cmd += ' --outputNum 1';
		cmd += ' --output0 "' + tmp + 'tmp_irr"';
		Krom.sysCommand(cmd);

		// Rad
		var faceSize = Std.int(image.width / 8);
		cmd = cmft;
		cmd += ' --input "' + path + '"';
		cmd += ' --filter radiance';
		cmd += ' --dstFaceSize ' + faceSize;
		cmd += ' --srcFaceSize ' + faceSize;
		cmd += ' --excludeBase false';
		cmd += ' --glossScale 8';
		cmd += ' --glossBias 3';
		cmd += ' --lightingModel blinnbrdf';
		cmd += ' --edgeFixup none';
		cmd += ' --numCpuProcessingThreads 4';
		cmd += ' --useOpenCL true';
		cmd += ' --clVendor anyGpuVendor';
		cmd += ' --deviceType gpu';
		cmd += ' --deviceIndex 0';
		cmd += ' --generateMipChain true';
		cmd += ' --inputGammaNumerator 1.0';
		cmd += ' --inputGammaDenominator 2.2';
		cmd += ' --outputGammaNumerator 1.0';
		cmd += ' --outputGammaDenominator 1.0';
		cmd += ' --outputNum 1';
		cmd += ' --output0 "' + tmp + 'tmp_rad"';
		cmd += ' --output0params hdr,rgbe,latlong';
		Krom.sysCommand(cmd);
		#end

		// Load irr
		Data.getBlob(tmp + "tmp_irr.c", function(blob:Blob) {
			var lines = blob.toString().split("\n");
			var band0 = lines[5];
			var band1 = lines[6];
			var band2 = lines[7];
			band0 = band0.substring(band0.indexOf("{"), band0.length);
			band1 = band1.substring(band1.indexOf("{"), band1.length);
			band2 = band2.substring(band2.indexOf("{"), band2.length);
			var band = band0 + band1 + band2;
			band = band.replace("{", "");
			band = band.replace("}", "");
			var ar = band.split(",");
			var buf = new Float32Array(27);
			for (i in 0...ar.length) buf[i] = Std.parseFloat(ar[i]);
			Scene.active.world.probe.irradiance = buf;
			Context.ddirty = 2;
			Data.deleteBlob(tmp + "tmp_irr.c");
		});

		// World envmap
		Scene.active.world.envmap = image;
		UITrait.inst.savedEnvmap = image;
		UITrait.inst.showEnvmapHandle.selected = UITrait.inst.showEnvmap = true;

		// Load mips
		var mips = Std.int(image.width / 1024);
		var mipsCount = 6 + mips;
		var mipsLoaded = 0;
		var mips:Array<Image> = [];
		while (mips.length < mipsCount + 2) mips.push(null);
		var mw = Std.int(image.width / 2);
		var mh = Std.int(image.width / 4);
		for (i in 0...mipsCount) {
			Data.getImage(tmp + "tmp_rad_" + i + "_" + mw + "x" + mh + ".hdr", function(mip:Image) {
				mips[i] = mip;
				mipsLoaded++;
				if (mipsLoaded == mipsCount) {
					// 2x1 and 1x1 mips
					mips[mipsCount] = Image.create(2, 1, TextureFormat.RGBA128);
					mips[mipsCount + 1] = Image.create(1, 1, TextureFormat.RGBA128);
					// Set radiance
					image.setMipmaps(mips);
					Scene.active.world.probe.radiance = image;
					Scene.active.world.probe.radianceMipmaps = mips;
					Context.ddirty = 2;
				}
			}, true); // Readable
			mw = Std.int(mw / 2);
			mh = Std.int(mh / 2);
		}
	}
}
