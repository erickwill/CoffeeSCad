// Generated by CoffeeScript 1.3.3
function main()
{
  var PingSensor, ping,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };


  PingSensor = (function() {

    PingSensor.prototype.width = 21.3;

    PingSensor.prototype.length = 45.7;

    PingSensor.prototype.height = 3.2;

    PingSensor.prototype.mount_holes_offset = 2.5;

    PingSensor.prototype.mount_holes_dia = 3.1;

    PingSensor.prototype.emire_dia = 16.17;

    PingSensor.prototype.emire_height = 12.3;

   PingSensor.prototype.emire_center_offset = 0;
   
   PingSensor.prototype.rounding_resolution = 5;

    function PingSensor(pos, rot) {
      this.pos = pos != null ? pos : [0, 0, 0];
      this.rot = rot != null ? rot : [0, 0, 0];
      this.render = __bind(this.render, this);

      this.emire_center_offset = (41.7 - this.emire_dia) / 2;
      OpenJsCad.log("Dia is: " + this.emire_dia);
      OpenJsCad.log("Center offset is: " + this.emire_center_offset);
    }
    
     PingSensor.prototype.render = function() {
      var eyecyl, holecyl, holecyl2, i, pcb, result, _i, _len, _ref;
      result = new CSG();
      pcb = CSG.cube({
        center: [0, 0, 0],
        radius: [this.width / 2, this.length / 2, this.height / 2]
      }).translate([0, 0, this.height / 2]).setColor(0.5, 0.5, 0.6);
      result = result.union(pcb);
      _ref = [-1, 1];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        eyecyl = CSG.cylinder({
          start: [0, 0, this.height],
          end: [0, 0, this.emire_height + this.height],
          radius: this.emire_dia / 2,
          resolution: this.rounding_resolution
        });
        eyecyl = eyecyl.translate([0, i * this.emire_center_offset, 0]).setColor(0.99, 0.85, 0.0);
        holecyl = CSG.cylinder({
          start: [0, 0, 0],
          end: [0, 0, this.height],
          radius: this.mount_holes_dia / 2,
          resolution: this.rounding_resolution
        });
        holecyl = holecyl.translate([this.width / 2 * i -i* this.mount_holes_offset, this.length / 2 * i -i* this.mount_holes_offset, 0]);
        result = result.union(eyecyl).subtract(holecyl);
      }
      return result.translate(this.pos).rotateX(this.rot[0]).rotateY(this.rot[1]).rotateZ(this.rot[2]);
    };

    return PingSensor;

  })();

  ping = new PingSensor();

  return ping.render();

}
