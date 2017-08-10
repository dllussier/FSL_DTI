#!/bin/bash

#use this when running on local workstation

#loop will continue to run for each individual subject one at a time
#please note that it can take up to 24 hours for complete pipeline to run for a single subject depending on cpu
for i in [subjects separated by one space]
do

#creates directories in which to move data that is needed for DTI preprocessing scripts
 mkdir $i
 mkdir $i/T1
 mkdir $i/DTI
 mkdir $i/DTI/raw/
 mkdir $i/DTI/nifti/
 mkdir $i/DTI/FSL/

#copies needed data from shared individual folder to working directory
#replace $filepath with filepath to data, $T1MPRAGE with T1 path and file name, and $dtidicomfolder with dti dicom filepath and folder name
 cp $filepath/$i/$T1MPRAGE $i/T1/T1.nii
 cp -r $filepath/$i/$dtidicomfolder $i/DTI/raw/DTI_dicoms

#reorients the T1-weighted MPRAGE and performs a rough extraction
 fsl5.0-fslreorient2std $i/T1/T1.nii.gz $i/FSL/T1/T1_reorient.nii.gz
 fsl5.0-bet $i/FSL/T1/T1_reorient.nii.gz $i/FSL/T1/T1_brain.nii.gz -f .1 -B -R

#converts dti dicoms to niftis
 dcm2niix $i/DTI/raw/DTI_dicoms/

#moves and renames files to set up folder to run DTI preporcessing scripts
 mv $i/DTI/raw/DTI_dicoms/x*WIP6dir*.nii.gz $i/DTI/nifti/x6dir.nii.gz
 mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.nii.gz $i/DTI/nifti/6dir.nii.gz
 mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.nii.gz $i/DTI/nifti/64dir.nii.gz
 mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.bval $i/DTI/nifti/6dir.bval
 mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.bvec $i/DTI/nifti/6dir.bvec
 mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.bval $i/DTI/nifti/64dir.bval
 mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.bvec $i/DTI/nifti/64dir.bvec

#runs eddy current correction on dti image
 fsl5.0-eddy_correct $i/DTI/FSL/64dir.nii DTI/FSL/64dir_ecc.nii.gz 0
   
#runs brain extraction tool to create binary mask and then renames mask appropriately
 fsl5.0-bet2 $i/DTI/FSL/64dir_ecc DTI/FSL/nodif_brain -f .3 -m

#fits tensors to the preprocessed diffusion weighted images
 fsl5.0-dtifit -k $i/DTI/FSL/64dir_ecc -o DTI/FSL/dti -m $i/DTI/FSL/nodif_brain_mask.nii.gz -r $i/DTI/FSL/bvecs -b $i/DTI/FSL/bvals

#runs bedpostx to build sampling distributions at each voxelto be used later for tractography
 fsl5.0-bedpostx  $i/DTI/FSL/

#registers DTI to the T1 MPRAGE
#replace $fslfilepath with the filepath to fsl reference image on the local machine
 fsl5.0-flirt -in $i/DTI/FSL/nodif_brain -ref FSL/T1/T1_brain.nii -omat $i/DTI/FSL.bedpostX/xfms/diff2str.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost mutualinfo
 fsl5.0-convert_xfm -omat $i/DTI/FSL.bedpostX/xfms/str2diff.mat -inverse $i/DTI/FSL.bedpostX/xfms/diff2str.mat
 fsl5.0-flirt -in $i/FSL/T1/T1_brain.nii -ref $fslfilepath/fsl/data/standard/avg152T1_brain -omat $i/DTI/FSL.bedpostX/xfms/str2standard.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost corratio
 fsl5.0-convert_xfm -omat $i/DTI/FSL.bedpostX/xfms/standard2str.mat -inverse $i/DTI/FSL.bedpostX/xfms/str2standard.mat
 fsl5.0-convert_xfm -omat $i/DTI/FSL.bedpostX/xfms/diff2standard.mat -concat $i/DTI/FSL.bedpostX/xfms/str2standard.mat $i/DTI/FSL.bedpostX/xfms/diff2str.mat
 fsl5.0-convert_xfm -omat $i/DTI/FSL.bedpostX/xfms/standard2diff.mat -inverse $i/DTI/FSL.bedpostX/xfms/diff2standard.mat

done
