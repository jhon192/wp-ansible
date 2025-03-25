# Create Environment
python3 -m venv env

# Activate Environment
source venv/bin/activate
#  Or in windows
.\env\Scripts\activate\

# Save requirements
pip freeze > requirements.txt

# Install requirements
pip install -r requirements.txt

# Run the app
python3 main.py

# Deactivate Environment
deactivate
