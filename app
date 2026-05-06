import streamlit as st
import pydeck as pdk
import pandas as pd
import numpy as np
import time
import random

st.set_page_config(layout="wide")
st.title("🚑 AI Emergency Response System (Final Version)")

# ------------------ BASE LOCATION ------------------
lat, lon = 17.3850, 78.4867

# ------------------ MULTIPLE AMBULANCES ------------------
ambulances = [
    (lat + 0.02, lon + 0.02),
    (lat - 0.015, lon + 0.01),
    (lat + 0.01, lon - 0.02)
]

# ------------------ ACCIDENT ------------------
accident = (lat, lon)

# ------------------ HOSPITALS ------------------
hospitals = [
    (lat - 0.02, lon - 0.015),
    (lat + 0.02, lon - 0.01),
    (lat - 0.015, lon + 0.02)
]

hospital_beds = [random.randint(2, 10) for _ in hospitals]

# ------------------ DISTANCE FUNCTION ------------------
def distance(a, b):
    return np.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)

# ------------------ SELECT BEST ------------------
selected_amb = min(ambulances, key=lambda x: distance(x, accident))
best_hospital = hospitals[np.argmax(hospital_beds)]

# ------------------ ROUTES ------------------
steps = 150
route1_lat = np.linspace(selected_amb[0], accident[0], steps)
route1_lon = np.linspace(selected_amb[1], accident[1], steps)

route2_lat = np.linspace(accident[0], best_hospital[0], steps)
route2_lon = np.linspace(accident[1], best_hospital[1], steps)

# ------------------ TRAFFIC ------------------
traffic = pd.DataFrame({
    "lat": lat + np.random.uniform(-0.02, 0.02, 40),
    "lon": lon + np.random.uniform(-0.02, 0.02, 40),
    "dx": np.random.uniform(-0.0003, 0.0003, 40),
    "dy": np.random.uniform(-0.0003, 0.0003, 40)
})

# ------------------ DASHBOARD ------------------
col1, col2, col3 = st.columns(3)
col1.metric("🚑 Ambulances", len(ambulances))
col2.metric("🏥 Beds Available", max(hospital_beds))
col3.metric("⚡ Response Time", "7.5 min", "-40%")

# ------------------ SIDEBAR ------------------
st.sidebar.title("📊 Live Dashboard")
st.sidebar.metric("🚑 Active Ambulances", len(ambulances))
st.sidebar.metric("🚧 Traffic Density", f"{random.randint(60,95)}%")
st.sidebar.metric("⚡ Avg Response Time", "7.5 min")
st.sidebar.metric("🏥 Beds Available", max(hospital_beds))

# ------------------ SIREN ------------------
def play_siren():
    st.markdown("""
    <audio autoplay loop>
      <source src="https://www.soundjay.com/transportation/sounds/ambulance-siren-01.mp3" type="audio/mpeg">
    </audio>
    """, unsafe_allow_html=True)
# ------------------ ALERTS ------------------
def send_alert():
    st.toast("🚨 Accident Alert Sent!")
    st.toast("🚑 Ambulance Dispatched!")
    st.toast("🏥 Hospital Notified!")

# ------------------ BUTTON ------------------
if st.button("🚨 Start Simulation"):

    st.error("🚨 Accident Detected!")
    send_alert()
    play_siren()

    placeholder = st.empty()
    rerouted = False

    # -------- PHASE 1 --------
    for i in range(steps):

        traffic["lat"] += traffic["dx"]
        traffic["lon"] += traffic["dy"]

        ambulance = pd.DataFrame({
            "lat": [route1_lat[i]],
            "lon": [route1_lon[i]]
        })

        path = list(zip(route1_lon[:i+1], route1_lat[:i+1]))

        # REROUTING
        if i == 70 and not rerouted:
            st.warning("🚧 Road Block! Rerouting...")
            route1_lon += 0.01
            rerouted = True

        deck = pdk.Deck(
            map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
            initial_view_state=pdk.ViewState(
                latitude=lat,
                longitude=lon,
                zoom=14,
                pitch=45,
            ),
            layers=[

                # 🚗 Traffic
                pdk.Layer(
                    "ScatterplotLayer",
                    traffic,
                    get_position="[lon, lat]",
                    get_color="[255,165,0]",
                    get_radius=60,
                ),

                # 🚨 Accident
                pdk.Layer(
                    "ScatterplotLayer",
                    pd.DataFrame({"lat":[accident[0]],"lon":[accident[1]]}),
                    get_position="[lon, lat]",
                    get_color="[255,0,0]",
                    get_radius=300,
                ),

                # 🚑 Ambulance
                pdk.Layer(
                    "ScatterplotLayer",
                    ambulance,
                    get_position="[lon, lat]",
                    get_color="[0,0,255]",
                    get_radius=250,
                ),

                # 🛣 Route
                pdk.Layer(
                    "PathLayer",
                    data=[{"path": path}],
                    get_path="path",
                    get_color="[0,0,255]",
                    width_min_pixels=4,
                ),
            ],
        )

        placeholder.pydeck_chart(deck)
        time.sleep(0.03)

    st.success("🚑 Reached Accident!")

    # -------- PHASE 2 --------
    st.info("🏥 Transporting to Hospital...")

    for i in range(steps):

        traffic["lat"] += traffic["dx"]
        traffic["lon"] += traffic["dy"]

        ambulance = pd.DataFrame({
            "lat": [route2_lat[i]],
            "lon": [route2_lon[i]]
        })

        path = list(zip(route2_lon[:i+1], route2_lat[:i+1]))

        deck = pdk.Deck(
            map_style="https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
            initial_view_state=pdk.ViewState(
                latitude=lat,
                longitude=lon,
                zoom=14,
                pitch=45,
            ),
            layers=[

                # 🚗 Traffic
                pdk.Layer(
                    "ScatterplotLayer",
                    traffic,
                    get_position="[lon, lat]",
                    get_color="[255,165,0]",
                    get_radius=60,
                ),

                # 🏥 Hospital
                pdk.Layer(
                    "ScatterplotLayer",
                    pd.DataFrame({"lat":[best_hospital[0]],"lon":[best_hospital[1]]}),
                    get_position="[lon, lat]",
                    get_color="[0,255,0]",
                    get_radius=350,
                ),

                # 🚑 Ambulance
                pdk.Layer(
                    "ScatterplotLayer",
                    ambulance,
                    get_position="[lon, lat]",
                    get_color="[0,0,255]",
                    get_radius=250,
                ),

                # 🛣 Route
                pdk.Layer(
                    "PathLayer",
                    data=[{"path": path}],
                    get_path="path",
                    get_color="[0,255,0]",
                    width_min_pixels=4,
                ),
            ],
        )

        placeholder.pydeck_chart(deck)
        time.sleep(0.05)

    st.success("🏥 Patient Delivered Successfully!")
    st.balloons()
