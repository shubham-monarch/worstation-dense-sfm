#!/bin/bash

# redirecting all output to a log.main 
exec >> logs/main.log 2>&1


# ---------------------------------------------
# [VIRTUAL ENVIRONMENT CHECK]
# ---------------------------------------------
if [[ "$VIRTUAL_ENV" == "" ]]
then
    echo "No virtual environment found. Terminating script."
    exit 1
fi


# =====================================
# [COPY SVO FILES FROM INPUT TO INPUT-BACKEND/SVO-FILES]
# =====================================

echo -e "\n"
echo "==============================="	
echo "COPYING SVO FILES FROM INPUT TO INPUT-BACKEND/SVO-FILES"
echo "==============================="
echo -e "\n"

 
# clear input-backend/svo-files
rm -rf input-backend/svo-files/*

# copy files from occ_input_dir to input-backend/svo-files
cp -r input/* input-backend/svo-files

INPUT_PATH=input-backend/svo-files

echo -e "\n"
echo "==============================="	
echo "INPUT_PATH: $INPUT_PATH"
echo "==============================="
echo -e "\n"


SVO_FILES=$(python3 -c "import scripts.utils_module.bash_utils as io;  io.get_file_list('${INPUT_PATH}')")
	
for SVO_FILE in $SVO_FILES;
do
    echo -e "\n"
	echo "==============================="
	echo "SVO_FILE: $SVO_FILE"
	echo "==============================="
	echo -e "\n"
	
	SVO_STEP=2
	python3 -m scripts.vo.main \
	--i=$SVO_FILE \
	--svo_step=$SVO_STEP

	# generate the JSON containing viable svo segments ==> 
	# [[2, 93], 
	# [263, 364], 
	# [365, 431]]
	JSON_FILE=$(python3 -c "import scripts.vo.main as vo;  vo.get_json_path('${SVO_FILE}')")

	echo -e "\n"
	echo "==============================="
	echo "JSON_FILE: $JSON_FILE"
	echo "==============================="
	echo -e "\n"
	

	# generate multiple config files using the (above)JSON_FILE 
	# CONFIG_FILES => list of generated config files
	# config file => 
	# {
    # "SVO_FILENAME": "front_2023-11-03-11-18-57.svo",
    # "SVO_START_IDX": 126,
    # "SVO_END_IDX": 208
	# }
	CONFIG_FILES=$(python3 -c "import scripts.utils_module.bash_utils as io;  io.generate_config_files_from_json('${JSON_FILE}')")
	
	idx=1

	# looping main-file.sh with [CONFIG_FILE in CONFIG_FILES]
	for CONFIG_FILE in $CONFIG_FILES;
	do 
		echo -e "\n"
		echo "==============================="
		echo "idx: $idx"
		echo "CONFIG_FILE: $CONFIG_FILE"
		echo "==============================="
		echo -e "\n"

		# break

		# Use jq to parse the JSON and extract values
		SVO_FILENAME=$(jq -r '.SVO_FILENAME' "$CONFIG_FILE")
		SVO_START_IDX=$(jq -r '.SVO_START_IDX' "$CONFIG_FILE")
		SVO_END_IDX=$(jq -r '.SVO_END_IDX' "$CONFIG_FILE")
		FARM_TYPE="vineyards"

		echo -e "\n"
		echo "==============================="
		echo "SVO_FILENAME: $SVO_FILENAME"
		echo "SVO_START_IDX: $SVO_START_IDX"
		echo "SVO_END_IDX: $SVO_END_IDX"
		echo "==============================="
		echo -e "\n"

		# response=$(./main-file.sh "$SVO_FILENAME" "$SVO_START_IDX" "$SVO_END_IDX" "$SVO_STEP")
		./main-file.sh "$SVO_FILENAME" "$SVO_START_IDX" "$SVO_END_IDX" "$SVO_STEP" "$FARM_TYPE"
		exit_status=$?

		echo -e "\n"
		echo "==============================="
		echo "exit_status: $exit_status"
		echo "==============================="
		echo -e "\n"

		if [ $exit_status -eq 0 ]; then
        	echo "$CONFIG_FILE" >> "logs/success.log"
    	fi


		((idx++))
	done

	# break
done

