include<parameters.scad>;
//rackTube

innerAlta=rackTubeAlta-2*rackTubeGrueso;
innerAncho=rackTubeAncho-2*rackTubeGrueso;

difference() {
cube([rackTubeAlta, rackTubeAncho, rackTubeLarga], center=true);
cube([innerAlta,innerAncho, rackTubeLarga*1.1], center=true); };	
