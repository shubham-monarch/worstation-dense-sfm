#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=dev
#SBATCH --gres=gpu:ada1 # Request one GPU
#SBATCH --job-name=sfm-test 


#module load sdks/cuda-11.3

#source /home/skumar/e33/bin/activate

# Parse JSON file and extract parameters


svo_path=$(python -c 'import json; config = json.load(open("config/config.json")); print(config.get("svo_path", ""))')
camera_params=$(python -c 'import json; config = json.load(open("config/config.json")); params = config.get("camera_params", []); print(",".join(str(x) for x in params))')


#echo $svo_path
#echo $camera_params


#srun --gres=gpu:1  \
#	python ../sparse-reconstruction/scripts/sparse-reconstruction.py \
#	--svo_dir="$svo_path" \
#	--camera_params="$camera_params"


source /home/skumar/e6/bin/activate

# SPARSE RECONSTRUCTION

SPARSE_RECONSTRUCTION_LOC="../sparse-reconstruction"
python "$(pwd)/${SPARSE_RECONSTRUCTION_LOC}/scripts/sparse-reconstruction.py" \
      --svo_dir="$svo_path" \
       --camera_params="$camera_params"

# RIG BUNDLE ADJUSTMENT

COLMAP_EXE_PATH=/usr/local/bin
RIG_BUNDLE_ADJUSTER_LOC="../rig-bundle-adjuster"
RIG_INPUT_PATH="${SPARSE_RECONSTRUCTION_LOC}/output/ref_locked"
RIG_OUTPUT_PATH="${RIG_BUNDLE_ADJUSTER_LOC}/output/"
RIG_CONFIG_PATH="config/rig.json"

rm -rf $RIG_OUTPUT_PATH
mkdir -p "$RIG_OUTPUT_PATH"

$COLMAP_EXE_PATH/colmap rig_bundle_adjuster \
	--input_path $RIG_INPUT_PATH \
	--output_path $RIG_OUTPUT_PATH \
	--rig_config_path $RIG_CONFIG_PATH \
	--BundleAdjustment.refine_focal_length 0 \
	--BundleAdjustment.refine_principal_point 0 \
	--BundleAdjustment.refine_extra_params 0 \
	--BundleAdjustment.refine_extrinsics 1 \
	--BundleAdjustment.max_num_iterations 100 \
	--estimate_rig_relative_poses False


#bash ../rig-bundle-adjuster/rig_ba.sh

#echo "RIG_INPUT_PATH ===> $RIG_INPUT_PATH"

#srun --gres=gpu:1 --pty bash rig-bundle-adjuster/rig_ba.sh
#srun --gres=gpu:1 --pty python ../dense-reconstruction/scripts/dense-reconstruction.py

