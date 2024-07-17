import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import PchipInterpolator

# Load Data
file_name = '../../D5-AHE-PATTERN-4K.txt'
data = pd.read_csv(file_name, delimiter='\t', skiprows=1, usecols=[3, 5, 7], names=['FieldH', 'CurrentA', 'VoltageV'])
data['RawResistanceXY'] = data['VoltageV'] / data['CurrentA']

# Calculate the difference of FieldH to find the turning point
dFieldH = np.diff(data['FieldH'])
turningPoint = np.where(dFieldH < 0)[0][0] + 1

# Indices for pos-Sweep and neg-Sweep
posIndex = np.arange(0, turningPoint)
negIndex = np.arange(turningPoint, len(data['FieldH']))

# Define the edges of the boxes
edges = np.arange(-8000, 8010, 10)
newFieldH = 0.5 * (edges[:-1] + edges[1:])

# Process pos-Sweep
posLoc = np.digitize(data['FieldH'][posIndex], edges) - 1
posResistance = data['VoltageV'][posIndex] / data['CurrentA'][posIndex]
newPosResistance = np.array([np.mean(posResistance[posLoc == i]) if np.any(posLoc == i) else np.nan for i in range(len(edges) - 1)])
newPosResistance = PchipInterpolator(newFieldH[np.isnan(newPosResistance) == False], newPosResistance[np.isnan(newPosResistance) == False])(newFieldH)

# Process neg-Sweep
negLoc = np.digitize(data['FieldH'][negIndex], edges) - 1
negResistance = data['VoltageV'][negIndex] / data['CurrentA'][negIndex]
newNegResistance = np.array([np.mean(negResistance[negLoc == i]) if np.any(negLoc == i) else np.nan for i in range(len(edges) - 1)])
newNegResistance = PchipInterpolator(newFieldH[np.isnan(newNegResistance) == False], newNegResistance[np.isnan(newNegResistance) == False])(newFieldH)

# Calculate anti-symmetric component for pos-Sweep & neg-Sweep
asymPosResistance = (newPosResistance - newNegResistance[::-1]) / 2
asymNegResistance = (newNegResistance - newPosResistance[::-1]) / 2

# Prepare data for plotting
newData_newFieldH = np.concatenate([newFieldH, newFieldH[::-1]])
newData_newResistance = np.concatenate([asymPosResistance, asymNegResistance])

# Plot Data
plt.figure()
plt.plot(data['FieldH'], data['RawResistanceXY'], 'g-', linewidth=2, label='raw AHE')
plt.plot(newFieldH, asymPosResistance, 'r-', linewidth=1, label='pos-Sweep')
plt.plot(newFieldH, asymNegResistance, 'b-', linewidth=1, label='neg-Sweep')

# Add title and axis labels
plt.legend(loc='best', frameon=False)
plt.xlabel('Field (Oe)')
plt.ylabel('Resistance (Ω)')
plt.grid(True)
plt.gca().tick_params(axis='both', which='major', labelsize=10, width=1.5)

# Save plot as image
plt.savefig('plot.png')
plt.show()
