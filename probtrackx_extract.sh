#!/bin/bash


module load fsl/5.0.10

flirt -in probtrackx/dti_FA.nii.gz -ref /apps/fsl/5.0.8/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz -applyxfm -init FSL.bedpostX/xfms/diff2standard.mat -out probtrackx/FA_2_MNI
fslstats probtrackx/FA_2_MNI -k probtrackx/fdt_paths.nii.gz -M -V > probtrackx/FA_probtrackx.txt

flirt -in probtrackx/dti_MD.nii.gz -ref /apps/fsl/5.0.8/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz -applyxfm -init FSL.bedpostX/xfms/diff2standard.mat -out probtrackx/MD_2_MNI
fslstats probtrackx/MD_2_MNI -k probtrackx/fdt_paths.nii.gz -M -V > probtrackx/MD_probtrackx.txt

probtrackx2 -x ../../Right_Amygdala.nii.gz -l --onewaycondition -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --sampvox=0.0 --xfm=FSL.bedpostX/xfms/standard2diff.mat --forcedir --opd -s FSL.bedpostX/merged -m FSL.bedpostX/nodif_brain_mask --dir=probtrackx --waypoints=../../Frontal_Medial_Cortex.nii.gz --waycond=AND
