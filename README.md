# Damage Tolerance of Adhesive Bonds Data Analysis & Regression Dashboard

## Title
Damage Tolerance of Adhesive Bonds Data Analysis & Regression Dashboard

## Description
This project presents an R Shiny web application designed for comprehensive data analysis and regression modeling of adhesive bond damage tolerance data. The dashboard allows users to upload their CSV datasets, perform data cleaning (NA handling, outlier management), conduct Exploratory Data Analysis (EDA) including histograms and boxplots, visualize correlations, perform automated feature selection using Boruta, train various machine learning regression models, and visualize their performance. The application also includes functionalities for comparing model predictions with theoretical values and generating detailed reports in HTML formats.

## Dataset Information
The application expects a CSV file containing experimental data related to the damage tolerance of adhesive bonds. Critical columns for the analysis include:
- `N`: Number of cycles
- `F`: Applied Force
- `d`: Displacement
- `a`: Crack length
- `dadN`: Crack growth rate
- `G_max`: Maximum strain energy release rate
- `Delta_sqrt.G.`: Range of square root of strain energy release rate
- `R`: Stress ratio
- `Cyclic_Energy`: Cyclic energy
- `Monotonic_Energy`: Monotonic energy
- `Total_Energy`: Total energy

The application performs automatic feature engineering to calculate:
- `alpha` and `beta` coefficients (from `log(a) ~ log(N)` linear regression per `Experiment_ID`)
- `dadN_theoretical` (based on Pascoe's formula, which depends on `G_max`, `Delta_sqrt.G.`, `R`)
- `Total_Energy_theoretical` (based on Pascoe's formula, which depends on `N`, `a_val`, `F`, `d`, `C_val`, `R`)
- `G_max_theoretical` (based on Pascoe's formula, which depends on `a_val`, `F`)

The `Experiment_ID`, `n_value`, `Base_Experiment`, and `w_value` columns are derived or merged from fixed calibration/specimen width data to support theoretical calculations.

## Code Information
The core of this project is the `RShiny_v2.0.R` script, which defines the User Interface (UI) and Server Logic for the Shiny application.
Additionally, the application uses an R Markdown file, `report_template.Rmd`, for generating dynamic analysis reports. This file must be present in the same directory as `RShiny_v2.0.R`.

- `RShiny_v2.0.R`: Contains the Shiny UI and server code, handling data loading, processing, EDA, model training, visualization, and report generation.
- `report_template.Rmd`: An R Markdown template used to generate comprehensive HTML reports summarising the analysis.

## Usage Instructions

To run this application:

1.  **Save the files:** Ensure `RShiny_v2.0.R` and `report_template.Rmd` are saved in the same directory on your local machine.
2.  **Install R and RStudio:** If you haven't already, download and install [R](https://cran.r-project.org/) and [RStudio Desktop](https://posit.co/downloads/rstudio-desktop/) (recommended IDE).
3.  **Install Required R Packages:** Open `RShiny_v2.0.R` in RStudio. The script itself has a section to install missing packages. Run this part of the code, or manually install them by running:
    ```R
    install.packages(c("shiny", "tidyverse", "caret", "Metrics", "glmnet",
                       "randomForest", "e1071", "Boruta", "corrplot", "DT",
                       "shinycssloaders", "gbm", "rpart", "xgboost", "rpart.plot",
                       "shinyWidgets", "ggplot2", "scales", "colourpicker",
                       "kknn", "pls", "gam", "Cubist", "brnn", "mgcv", 
                       "rmarkdown", "kernlab", "qrnn", "knitr", "plotly"))
    ```
4.  **Run the Shiny Application:** In RStudio, with `RShiny_v2.0.R` open, click the "Run App" button (usually in the top right corner of the script editor).

Once the application launches in your browser:

1.  **Upload CSV File:** Click "Browse..." under "Upload CSV File" in the sidebar to upload your experimental data.
2.  **Select Target Variable:** Choose the dependent variable for regression analysis (e.g., `dadN`, `Total_Energy`, `G_max`).
3.  **Outlier Management (Optional):** Enable and configure outlier handling settings.
4.  **Configure Model Training:** Adjust the training set percentage, random seed, and number of cross-validation folds. Select the regression models you wish to train.
5.  **Run Analysis:** Click "Run Analysis" to perform data processing, feature selection, and model training.
6.  **Explore Tabs:** Navigate through the tabs to view data previews, EDA plots, correlation matrices, Boruta feature selection results, model performance metrics, and actual vs. predicted plots.
7.  **Generate Reports:** Use the "Generate HTML Report" buttons in the "Reporting & Export" tab to create a comprehensive summary of your analysis.
8.  **Export Data/Metrics:** Download the cleaned data or all model metrics as CSV files.

## Requirements

**R Packages:**
- `shiny`
- `tidyverse`
- `caret`
- `Metrics`
- `glmnet`
- `randomForest`
- `e1071`
- `Boruta`
- `corrplot`
- `DT`
- `shinycssloaders`
- `gbm`
- `rpart`
- `xgboost`
- `rpart.plot`
- `shinyWidgets`
- `ggplot2`
- `scales`
- `colourpicker`
- `kknn`
- `pls`
- `gam`
- `Cubist`
- `brnn`
- `mgcv`
- `rmarkdown`
- `kernlab`
- `qrnn`
- `knitr`
- `plotly`

**External Files:**
- `report_template.Rmd` (must be in the same directory as `RShiny_v2.0.R`)

## Methodology

1.  **Data Ingestion and Initial Cleaning:**
    * Users upload a CSV file.
    * Columns are automatically converted to numeric where possible, handling comma-decimal separators.
    * NA values in critical columns (`N`, `F`, `d`, `a`, `dadN`, `G_max`, `Delta_sqrt.G.`, `R`, `Cyclic_Energy`, `Monotonic_Energy`, `Total_Energy`) are removed.
    * **Feature Engineering:**
        * `Experiment_ID` and `Base_Experiment` are extracted/derived from the filename and used for merging fixed calibration (`n_value`) and specimen width (`w_value`) data.
        * `alpha` and `beta` coefficients are calculated for each `Experiment_ID` by fitting `log(a) ~ log(N)`.
        * `dadN_theoretical`, `Total_Energy_theoretical`, and `G_max_theoretical` are calculated based on predefined Pascoe-like theoretical models, incorporating merged and calculated features.

2.  **Outlier Management:**
    * Optional Z-score based outlier detection and handling (removal, capping, or replacement with NA) for all numeric columns.

3.  **Exploratory Data Analysis (EDA):**
    * **Data Preview:** Displays the raw uploaded data in a table.
    * **Missing Values Summary:** Shows counts of `NA` values per column.
    * **Outlier Summary:** Reports on outliers detected and handled (if enabled).
    * **Histograms:** Visualizes the distribution of all numeric features.
    * **Boxplots:** Displays boxplots for selected numeric features to show spread and potential outliers.
    * **Correlation Matrix:** An interactive heatmap showing Pearson correlations between the selected target variable and its potential predictors.

4.  **Feature Selection (Boruta):**
    * The Boruta algorithm is employed to identify relevant features for the selected target variable.
    * It performs a random forest-based wrapper algorithm to determine feature importance by comparing original attributes' importance with shuffled (shadow) attributes.
    * Only 'Confirmed' features from Boruta are used for subsequent model training. If no features are confirmed, all initial potential predictors are used as a fallback.

5.  **Model Training and Evaluation:**
    * The cleaned data is split into training and test sets based on a user-defined ratio.
    * Several machine learning regression models can be selected by the user, including:
        * Linear Regression (`lm`)
        * Ridge Regression (`ridge`)
        * Lasso Regression (`lasso`)
        * Elastic Net Regression (`glmnet`)
        * Random Forest (`rf`)
        * Support Vector Machine (Linear & Radial) (`svmLinear`, `svmRadial`)
        * Gradient Boosting (`gbm`)
        * Decision Tree (`rpart`)
        * XGBoost (`xgbTree`)
        * K-Nearest Neighbors (`knn`)
        * Partial Least Squares (`pls`)
        * Generalized Additive Model (`gam`)
        * Bayesian Regularized Neural Network (`brnn`)
        * Gaussian Process Regression (Radial) (`gaussprRadial`)
        * Quantile Regression (`qrnn`)
    * Models are trained using `caret::train` with K-fold cross-validation (user-defined folds).
    * Performance metrics (RMSE, R-squared, MAE, MAPE, MdAE, RMSLE) are calculated for the training set, test set, and cross-validation results.
    * Training times for each model are recorded.

6.  **Visualization of Model Performance:**
    * **Training Time Plot:** Bar chart comparing the training time of selected models.
    * **Actual vs. Predicted Plot:** Interactive scatter plots showing actual vs. predicted values for each model on the test set, along with a 1:1 reference line.
    * **Predicted vs. Residual Plot:** Interactive scatter plots showing predicted values vs. residuals for each model on the test set, with a zero-residual reference line.

7.  **Explainable Models:**
    * **Linear Regression:** Displays the mathematical equation of the fitted LM model with coefficients and a bar plot of coefficient values.
    * **Decision Tree:** Visualizes the `rpart` decision tree structure.

8.  **Comparison with Thesis/Theoretical Model:**
    * Allows comparison of selected ML model predictions with a "Theoretical Model" based on the engineered theoretical target values.
    * Interactive scatter plot and a summary table for comparative MAE, R-squared, and Correlation.

9.  **Reporting and Export:**
    * Generates comprehensive analysis reports in HTML formats, including all EDA, feature selection, model metrics, and plots.
    * Exports the cleaned data and all model metrics as CSV files.

## Citations (if applicable)

Please cite any relevant research that utilizes or informs the theoretical models or specific methodologies applied in this analysis. For example:

* Pascoe, J. A. (2016). *Characterisation of Fatigue Crack Growth in Adhesive Bonds*. https://doi.org/10.4233/uuid:ebbf552a-ce98-4ab6-b9cc-0b939e12ba8b
* Pascoe, John Alan, René Christiaan Alderliesten, and Rinze Benedictus. (2016). *Damage Tolerance of Adhesive Bonds - Dataset II. TU Delft.* https://doi.org/10.4121/UUID:AC105275-9DD6-4846-841D-4B0F164E6503
* Relevant Machine Learning algorithm papers or libraries.

## How to Cite This Software

If you use this R Shiny application in your research, please cite it as follows to acknowledge the development of this tool:

**Cakir, M. (2025). *Damage Tolerance of Adhesive Bonds: Data Analysis & Regression Dashboard* (Version v2.0.1) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.17216129**

*BibTeX Entry:*
```bibtex
@software{Cakir_2025_17216129,
  author    = {Cakir, Mustafa},
  title     = {{Damage Tolerance of Adhesive Bonds: Data Analysis & Regression Dashboard}},
  version   = {v2.0.1},
  publisher = {Zenodo},
  year      = {2025},
  doi       = {10.5281/zenodo.17216129},
  url       = {[https://doi.org/10.5281/zenodo.17216129](https://doi.org/10.5281/zenodo.17216129)}
}
```
## Conclusions

This study successfully developed and implemented an R Shiny dashboard for the comprehensive analysis of adhesive bond damage tolerance data. The application effectively streamlines the process from raw data ingestion and cleaning to advanced regression modeling and performance evaluation. The integrated data preprocessing, feature engineering capabilities for theoretical values, and robust outlier management contribute to the reliability of the analysis. The Boruta algorithm proved effective in identifying relevant predictors, ensuring that subsequent models were trained on a focused and impactful set of features. The dashboard's ability to train and compare a diverse array of machine learning models provides users with a broad perspective on predictive performance for the specified target variables. Visualization of model metrics, actual vs. predicted values, and residuals offers critical insights into model accuracy and error characteristics. Furthermore, the inclusion of explainable models like Linear Regression and Decision Trees, coupled with comparative analyses against theoretical models, enhances the interpretability and contextual relevance of the findings. The automated report generation functionality significantly improves the reproducibility and dissemination of the analytical results, providing a structured summary of all key steps and outcomes.

## Limitations: Identify limitations in your study

Despite its comprehensive features, this study and the developed application have several limitations. Firstly, the predefined theoretical models (dadN_theoretical, Total_Energy_theoretical, G_max_theoretical) and the fixed calibration/specimen width data are highly specific to the "Damage Tolerance of Adhesive Bonds" domain as derived from Pascoe's thesis. Their universal applicability to other adhesive bond types or different experimental setups without modification is limited. Secondly, the Z-score based outlier detection method assumes a normal distribution of data, which may not always hold true for all features, potentially leading to suboptimal outlier handling in non-normally distributed data. More advanced, distribution-agnostic outlier detection techniques could improve robustness. Thirdly, while the Boruta feature selection algorithm is powerful, it can sometimes categorize features as 'Tentative' when high correlations exist among predictors or with very large feature sets, necessitating further domain expertise for conclusive selection. Fourthly, although the application offers a wide range of machine learning models, the level of hyperparameter tuning is primarily driven by caret's default or simple grid search configurations. For achieving absolute state-of-the-art performance, a more exhaustive and customized hyperparameter optimization strategy (e.g., Bayesian optimization, more extensive grid/random searches) might be necessary, which would significantly increase training times. Lastly, while Linear Regression and Decision Trees provide direct interpretability, the dashboard does not integrate advanced explainable AI (XAI) techniques (like SHAP or LIME) for more complex, "black-box" models such as Random Forest or XGBoost. Such additions would further enhance the transparency and trust in these high-performance models.

## License & Contribution Guidelines

This project is open-source and available under the [MIT License](LICENSE.md).

Contributions are welcome! If you find a bug, have a feature request, or want to contribute code, please open an issue or submit a pull request on the GitHub repository.
