# Attempt to parse and visualize the data again with additional checks to handle potential missing entries
import re
import matplotlib.pyplot as plt
from datetime import datetime

# Read the file
file_path = 'testresultLog9.txt'
with open(file_path, 'r', encoding="utf-8") as file:
    log_data = file.readlines()

# Initialize lists to hold data
timestamps = []
take_picture_durations = []
save_to_durations = []
copy_to_public_durations = []
load_image_file_durations = []

# Parse the log data
for line in log_data:
    if "Picture capture started at" in line:
        timestamp_str = line.split('at: ')[-1].strip()
        timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S.%f')
        timestamps.append(timestamp)
    elif "takePicture duration" in line:
        duration = int(re.search(r'\d+', line.split(':')[-1]).group())
        take_picture_durations.append(duration)
    elif "saveTo duration" in line:
        duration = int(re.search(r'\d+', line.split(':')[-1]).group())
        save_to_durations.append(duration)
    elif "copyToPublicA duration" in line:
        duration = int(re.search(r'\d+', line.split(':')[-1]).group())
        copy_to_public_durations.append(duration)
    elif "loadimageFileSS duration" in line:
        duration = int(re.search(r'\d+', line.split(':')[-1]).group())
        load_image_file_durations.append(duration)

# Ensure all lists are the same length by filling in missing values with None
max_length = max(len(timestamps), len(take_picture_durations), len(save_to_durations), len(copy_to_public_durations), len(load_image_file_durations))
take_picture_durations += [None] * (max_length - len(take_picture_durations))
save_to_durations += [None] * (max_length - len(save_to_durations))
copy_to_public_durations += [None] * (max_length - len(copy_to_public_durations))
load_image_file_durations += [None] * (max_length - len(load_image_file_durations))

# Plot the data
plt.figure(figsize=(15, 10))

plt.subplot(4, 1, 1)
plt.plot(timestamps, take_picture_durations, marker='o')
plt.title('Take Picture Duration')
plt.ylabel('Duration (ms)')
plt.xticks(rotation=45)

plt.subplot(4, 1, 2)
plt.plot(timestamps, save_to_durations, marker='o')
plt.title('Save To Duration')
plt.ylabel('Duration (ms)')
plt.xticks(rotation=45)

plt.subplot(4, 1, 3)
plt.plot(timestamps, copy_to_public_durations, marker='o')
plt.title('Copy To Public Duration')
plt.ylabel('Duration (ms)')
plt.xticks(rotation=45)

plt.subplot(4, 1, 4)
plt.plot(timestamps, load_image_file_durations, marker='o')
plt.title('Load Image File Duration')
plt.ylabel('Duration (ms)')
plt.xticks(rotation=45)

plt.tight_layout()
plt.savefig('processing_durations_plot.png')
plt.show()

# Save the plot
output_path = 'processing_durations_plot.png'
output_path
