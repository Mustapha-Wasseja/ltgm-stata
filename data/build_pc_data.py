"""
Build ltgm_pc_data.dta from pc_countries_v2.csv + standard_countries_v2.csv

Merges PC-specific columns (public capital shares, efficiency, investment
splits) with standard LTGM parameters (GDP, TFP, depreciation, etc.) to
create a single bundled dataset for the Public Capital model.

Produces: ltgm_pc_data.dta (Stata 13 compatible, version 117)
"""

import os
import numpy as np
import pandas as pd

DATA_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_DIR = os.path.join(DATA_DIR, "csv")

# =====================================================================
# Load PC data
# =====================================================================
pc = pd.read_csv(os.path.join(CSV_DIR, "pc_countries_v2.csv"))
# Drop duplicate header rows
pc = pc[pc["countrycode"] != "countrycode"].copy()
pc = pc[pc["countrycode"].notna() & (pc["countrycode"] != "")].copy()
pc.rename(columns={"countrycode": "iso3"}, inplace=True)

# Force numeric
pc_num_cols = [
    "kg_kp_ratio", "kg_k_share", "kg_kp_fad", "kg_k_fad",
    "iei", "pimi", "efficiency_pimi",
    "ig_i_20yr", "ig_i_15yr", "ig_i_10yr", "ig_i_5yr", "ig_i_current",
    "ip_y", "i_y", "ig_y",
]
for c in pc_num_cols:
    if c in pc.columns:
        pc[c] = pd.to_numeric(pc[c], errors="coerce")

print(f"PC data: {len(pc)} countries loaded")

# =====================================================================
# Load standard data
# =====================================================================
std = pd.read_csv(os.path.join(CSV_DIR, "standard_countries_v2.csv"))
std = std[std["countrycode"] != "countrycode"].copy()
std = std[std["countrycode"].notna() & (std["countrycode"] != "")].copy()
std.rename(columns={"countrycode": "iso3", "country": "country_name"}, inplace=True)

# Force numeric on all columns we need
std_num_cols = [
    "delta_pwt110", "delta_pwt100", "delta_pwt1001",
    "labsh_pwt110", "labsh_pwt100", "labsh_pwt1001",
    "ky_pwt110", "ky_pwt100", "ky_pwt1001", "ky_mfmod", "ky_fad",
    "gni_pc_atlas", "gdp_pc_level", "gdp_pc_wdi",
    "tfp_growth_pwt110_20yr", "tfp_growth_pwt110_10yr", "tfp_growth_pwt110_05yr",
    "tfp_growth_pwt90_20yr", "tfp_growth_pwt91_20yr", "tfp_growth_pwt100_20yr",
    "inv_gdp_wdi_10yr", "inv_gdp_pwt_10yr", "inv_gdp_wdi_20yr",
    "inv_gdp_wdi_05yr", "inv_gdp_weo_forecast",
    "pop_growth_med_2024", "pop_growth_med_2025", "pop_growth_med_2030",
    "poverty_215", "gini",
    "lfp_total", "lfp_male", "lfp_female",
    "hc_growth_pwt110_10yr", "hc_growth_pwt110_20yr",
    "watp_1564_med_2025", "watp_1564_med_2030",
]
for c in std_num_cols:
    if c in std.columns:
        std[c] = pd.to_numeric(std[c], errors="coerce")

print(f"Standard data: {len(std)} countries loaded")


# =====================================================================
# Build standard parameters (same fallback cascades as build_ltgm_data.do)
# =====================================================================
def fallback(*cols):
    """Return first non-NaN value across columns."""
    result = cols[0].copy()
    for c in cols[1:]:
        result = result.fillna(c)
    return result


# y0: GDP per capita
std["y0"] = fallback(std["gni_pc_atlas"], std.get("gdp_pc_wdi", pd.Series(dtype=float)), std["gdp_pc_level"])

# s: investment rate
std["s"] = fallback(
    std["inv_gdp_wdi_10yr"], std["inv_gdp_pwt_10yr"],
    std["inv_gdp_wdi_20yr"], std["inv_gdp_wdi_05yr"],
    std.get("inv_gdp_weo_forecast", pd.Series(dtype=float)),
)
if std["s"].max() > 1:
    std["s"] = std["s"] / 100

# delta
std["delta"] = fallback(std["delta_pwt110"], std["delta_pwt100"], std["delta_pwt1001"])
std["delta"] = std["delta"].fillna(0.05)
if std["delta"].max() > 1:
    std["delta"] = std["delta"] / 100

# alpha = 1 - labour share
std["alpha"] = 1 - fallback(std["labsh_pwt110"], std["labsh_pwt100"], std["labsh_pwt1001"])
std["alpha"] = std["alpha"].fillna(0.35)
std.loc[(std["alpha"] <= 0.05) | (std["alpha"] >= 0.95), "alpha"] = 0.35

# ky0
std["ky0"] = fallback(std["ky_pwt110"], std["ky_pwt100"], std["ky_pwt1001"],
                       std["ky_mfmod"], std["ky_fad"])
std["ky0"] = std["ky0"].fillna(2.5)

# g_tfp with plausibility floor
std["g_tfp"] = std["tfp_growth_pwt110_20yr"].copy()
# Plausibility cascade: if PWT 11.0 is non-negative but < 0.005
mask_low = std["g_tfp"].notna() & (std["g_tfp"] >= 0) & (std["g_tfp"] < 0.005)
std.loc[mask_low & std["tfp_growth_pwt100_20yr"].notna(), "g_tfp"] = std.loc[
    mask_low & std["tfp_growth_pwt100_20yr"].notna(), "tfp_growth_pwt100_20yr"
]
mask_low = std["g_tfp"].notna() & (std["g_tfp"] >= 0) & (std["g_tfp"] < 0.005)
std.loc[mask_low & std["tfp_growth_pwt90_20yr"].notna(), "g_tfp"] = std.loc[
    mask_low & std["tfp_growth_pwt90_20yr"].notna(), "tfp_growth_pwt90_20yr"
]
std["g_tfp"] = std["g_tfp"].fillna(std["tfp_growth_pwt110_10yr"])
std["g_tfp"] = std["g_tfp"].fillna(std["tfp_growth_pwt110_05yr"])
std["g_tfp"] = std["g_tfp"].fillna(0.01)
if std["g_tfp"].max() > 0.5:
    std["g_tfp"] = std["g_tfp"] / 100

# g_pop
std["g_pop"] = fallback(std["pop_growth_med_2025"], std["pop_growth_med_2024"],
                         std["pop_growth_med_2030"])
std["g_pop"] = std["g_pop"].fillna(0.02)
if std["g_pop"].max() > 0.5:
    std["g_pop"] = std["g_pop"] / 100

# hc_growth
std["hc_growth"] = fallback(std["hc_growth_pwt110_10yr"], std["hc_growth_pwt110_20yr"])
std["hc_growth"] = std["hc_growth"].fillna(0.005)
if std["hc_growth"].max() > 0.5:
    std["hc_growth"] = std["hc_growth"] / 100

# g_watp: WATP growth rate = annualized change in working-age population share
# watp_1564_med_YYYY columns are LEVELS (e.g. 0.60 = 60% working age), NOT growth rates
# Compute: g_watp = (watp_2030 / watp_2025)^(1/5) - 1  (annualized over 5 years)
_watp_2025 = std.get("watp_1564_med_2025", pd.Series(dtype=float))
_watp_2030 = std.get("watp_1564_med_2030", pd.Series(dtype=float))
_watp_2035 = std.get("watp_1564_med_2035", pd.Series(dtype=float))
# Primary: 2025->2030 annualized
std["g_watp"] = np.where(
    _watp_2025.notna() & _watp_2030.notna() & (_watp_2025 > 0),
    (_watp_2030 / _watp_2025) ** (1/5) - 1,
    np.nan
)
std["g_watp"] = pd.to_numeric(std["g_watp"], errors="coerce")
# Fallback: 2030->2035 annualized
mask = std["g_watp"].isna() & _watp_2030.notna() & _watp_2035.notna() & (_watp_2030 > 0)
std.loc[mask, "g_watp"] = (_watp_2035[mask] / _watp_2030[mask]) ** (1/5) - 1
# Final fallback: 0 (stable WATP share)
std["g_watp"] = std["g_watp"].fillna(0)

# povshare
std["povshare"] = std["poverty_215"].copy()
if std["povshare"].max() > 1:
    std["povshare"] = std["povshare"] / 100
std["povshare"] = std["povshare"].fillna(0)

std["gini_coef"] = std["gini"]
std["lfp_rate"] = std["lfp_total"]
std["g_lfp"] = 0.0

# =====================================================================
# Merge PC + Standard
# =====================================================================
# Keep only PC-specific columns from pc
pc_keep = pc[["iso3", "kg_k_share", "iei", "ig_y", "ip_y", "i_y",
              "ig_i_10yr", "ig_i_20yr"]].copy()

merged = std.merge(pc_keep, on="iso3", how="left")
print(f"After merge: {len(merged)} countries")

# =====================================================================
# Derive PC parameters
# =====================================================================

# Public capital share: default 0.30
merged["kg_k_share"] = merged["kg_k_share"].fillna(0.30)

# Public and private K/Y
merged["pub_ky_ratio"] = merged["kg_k_share"] * merged["ky0"]
merged["priv_ky_ratio"] = (1 - merged["kg_k_share"]) * merged["ky0"]

# Public investment / GDP
merged["pub_inv_gdp"] = merged["ig_y"].copy()
mask = merged["pub_inv_gdp"].isna() & merged["ig_i_10yr"].notna() & merged["s"].notna()
merged.loc[mask, "pub_inv_gdp"] = merged.loc[mask, "ig_i_10yr"] * merged.loc[mask, "s"]
mask = merged["pub_inv_gdp"].isna() & merged["ig_i_20yr"].notna() & merged["s"].notna()
merged.loc[mask, "pub_inv_gdp"] = merged.loc[mask, "ig_i_20yr"] * merged.loc[mask, "s"]
merged["pub_inv_gdp"] = merged["pub_inv_gdp"].fillna(0.05)

# Private investment / GDP
merged["priv_inv_gdp"] = merged["ip_y"].copy()
mask = merged["priv_inv_gdp"].isna() & merged["s"].notna()
merged.loc[mask, "priv_inv_gdp"] = merged.loc[mask, "s"] - merged.loc[mask, "pub_inv_gdp"]
merged["priv_inv_gdp"] = merged["priv_inv_gdp"].clip(lower=0.01)
merged["priv_inv_gdp"] = merged["priv_inv_gdp"].fillna(0.15)

# Public efficiency (IEI)
merged["pub_efficiency"] = merged["iei"].fillna(0.60).clip(0.1, 1.0)

# Data year
merged["data_year"] = 2022

# =====================================================================
# Select and save
# =====================================================================
final_cols = [
    "iso3", "country_name", "income_group", "data_year",
    "y0", "s", "delta", "alpha", "ky0",
    "g_tfp", "g_pop", "g_watp", "hc_growth", "g_lfp",
    "lfp_rate", "povshare", "gini_coef",
    "kg_k_share", "pub_ky_ratio", "priv_ky_ratio",
    "pub_inv_gdp", "priv_inv_gdp", "pub_efficiency",
]

result = merged[final_cols].copy()
result = result.sort_values("country_name").reset_index(drop=True)

# Clean string columns for Stata 13 (latin-1 only, no Unicode)
for col in ["iso3", "country_name", "income_group"]:
    result[col] = (
        result[col]
        .fillna("")
        .str.encode("latin-1", errors="replace")
        .str.decode("latin-1")
    )

# Save as Stata 13 compatible .dta (version 117)
out_path = os.path.join(DATA_DIR, "ltgm_pc_data.dta")
result.to_stata(out_path, write_index=False, version=117)
print(f"\nSaved: {out_path}")
print(f"Total countries: {len(result)}")

# Diagnostics
print("\n=== LTGM Public Capital Country Dataset ===")
for col in ["y0", "s", "ky0", "g_tfp", "g_pop", "pub_ky_ratio",
            "priv_ky_ratio", "pub_inv_gdp", "priv_inv_gdp", "pub_efficiency"]:
    n_ok = result[col].notna().sum()
    n_miss = result[col].isna().sum()
    print(f"  {col:22s}: {n_ok} available, {n_miss} missing")

# Quick sanity check on a few countries
for c in ["KEN", "GHA", "BRA", "USA"]:
    row = result[result["iso3"] == c]
    if len(row) > 0:
        r = row.iloc[0]
        print(f"\n  {c} ({r['country_name']}):")
        print(f"    pub_ky={r['pub_ky_ratio']:.2f}  priv_ky={r['priv_ky_ratio']:.2f}  "
              f"pub_inv={r['pub_inv_gdp']:.3f}  priv_inv={r['priv_inv_gdp']:.3f}  "
              f"eff={r['pub_efficiency']:.3f}")
