include<parameters.scad>;
//heliostat rack

innerAlta=rackTubeAlta-2*rackTubeGrueso;
innerAncho=rackTubeAncho-2*rackTubeGrueso;

module tublar(larga)
{
	difference() {
	cube([rackTubeAlta, rackTubeAncho, larga], center=true);
	cube([innerAlta,innerAncho, larga*1.1], center=true); 
	}
}

module base()
{
rotate(a=[0, 90,0]) translate([-tubeHeight/2, 0, tubeHeight/2+rackTubeAncho/2]) tublar(tubeHeight);
rotate(a=[0, 90,0]) translate([-tubeHeight/2, tubeWidth, tubeHeight/2+rackTubeAncho/2]) tublar(tubeHeight);
rotate(a=[90, 0,0]) translate([rackTubeAlta, tubeWidth/2-rackTubeAlta, -tubeWidth/2]) tublar(tubeWidth);

translate([0,0,2*baseLength-2*rackTubeAncho])difference(){
translate( [rackTubeGrueso,-rackTubeGrueso,0]) cube([rackTubeAncho, rackTubeAncho, baseLength], center=true);
cube([rackTubeAncho, rackTubeAncho, baseLength*2], center=true);
}

translate([0,tubeWidth,2*baseLength-2*rackTubeAncho])rotate(a=[180,0,0])difference(){
translate( [rackTubeGrueso,-rackTubeGrueso,0]) cube([rackTubeAncho, rackTubeAncho, baseLength], center=true);
cube([rackTubeAncho, rackTubeAncho, baseLength*2], center=true);
}
}

translate( [0, 0, tubeHeight] ) tublar(rackTubeLarga);
translate( [0, tubeWidth, tubeHeight] ) tublar(rackTubeLarga);
translate([0,0,baseLength+rackTubeLarga/2]) base();
translate([0,0,2*baseLength-rackTubeLarga/2]) base();
translate([0,0,baseLength+rackTubeLarga/2-260]) base();
translate([0,0,baseLength+rackTubeLarga/2-260-292]) base();
translate([0,0,baseLength+rackTubeLarga/2-260-341]) base();
translate([0,0,baseLength+rackTubeLarga/2-260-402]) base();
translate([0,0,baseLength+rackTubeLarga/2-260-519]) base();
translate([0,0,baseLength+rackTubeLarga/2-260-815]) base();