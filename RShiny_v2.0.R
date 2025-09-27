# Install & load required packages
packages <- c("shiny", "tidyverse", "caret", "Metrics", "glmnet",
              "randomForest", "e1071", "Boruta", "corrplot", "DT",
              "shinycssloaders", "gbm", "rpart", "xgboost", "rpart.plot",
              "shinyWidgets", "ggplot2", "scales", "colourpicker",
              "kknn", "pls", "gam", "Cubist", "brnn", "mgcv", 
              "rmarkdown", "kernlab", "qrnn", "knitr", "plotly")
to_install <- setdiff(packages, rownames(installed.packages()))
if (length(to_install)) install.packages(to_install)
lapply(packages, library, character.only = TRUE)

# Define UI
ui <- fluidPage(
  titlePanel("Data Analysis & Regression Dashboard for Damage Tolerance of Adhesive Bonds Dataset"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload CSV File", accept = ".csv"),
      uiOutput("target_selector"),
      uiOutput("boxplot_feature_selector"),
      
      # Outlier Management UI
      h4("Outlier Management"),
      checkboxInput("enable_outlier_mgt", "Enable Outlier Management", value = FALSE),
      conditionalPanel(
        condition = "input.enable_outlier_mgt == true",
        numericInput("zscore_threshold", "Z-score Threshold for Outliers", value = 3, min = 1, step = 0.5),
        radioButtons("outlier_method", "Outlier Handling Method:",
                     choices = c("Remove Rows" = "remove",
                                 "Cap Outliers (to Z-score bounds)" = "cap",
                                 "Replace with NA" = "na"),
                     selected = "remove")
      ),
      
      sliderInput("split_ratio", "Training Set Percentage", min = 60, max = 90, value = 80),
      numericInput("seed", "Random Seed", value = 123),
      numericInput("cv_folds", "Number of CV Folds", value = 5, min = 2),
      checkboxGroupInput("models", "Select Models to Train:",
                         choices = list(
                           "Linear Regression"         = "lm",
                           "Ridge Regression"          = "ridge",
                           "Lasso Regression"          = "lasso",
                           "Elastic Net Regression"    = "glmnet",
                           "Random Forest"             = "rf",
                           "Support Vector Machine (Linear)"= "svmLinear",
                           "Support Vector Machine (Radial)" = "svmRadial",
                           "Gradient Boosting"         = "gbm",
                           "Decision Tree"             = "rpart",
                           "XGBoost"                   = "xgbTree",
                           "K-Nearest Neighbors"       = "knn",
                           "Partial Least Squares"     = "pls",
                           "Generalized Additive Model" = "gam",
                           "Bayesian Regularized Neural Network" = "brnn",
                           "Gaussian Process Regression (Radial)" = "gaussprRadial",
                           "Quantile Regression (QRNN)" = "qrnn"
                         ),
                         selected = c("lm","ridge","lasso","glmnet","rf","svmLinear","svmRadial","gbm","rpart",
                                      "xgbTree", "knn", "pls", "gam", "brnn", "gaussprRadial", "qrnn")), # Updated selected models
      actionButton("run", "Run Analysis", class = "btn btn-primary"),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        id = "main_tabs",
        tabPanel("Data Preview", DTOutput("data_preview") %>% withSpinner()),
        tabPanel("EDA",
                 tabsetPanel(
                   tabPanel("Summary", verbatimTextOutput("missing_summary"), verbatimTextOutput("outlier_summary")),
                   tabPanel("Histograms", plotOutput("histograms") %>% withSpinner(),
                            h4("Settings & Download"), uiOutput("hist_plot_controls"), downloadButton("download_hist", "Download Histograms (High-Res)")),
                   tabPanel("Boxplots", plotOutput("boxplots") %>% withSpinner(),
                            h4("Settings & Download"), uiOutput("box_plot_controls"), downloadButton("download_box", "Download Boxplots (High-Res)"))
                 )
        ),
        tabPanel("Correlation Matrix", plotlyOutput("cor_plot", height = "600px") %>% withSpinner(),
                 h4("Settings & Download"), uiOutput("cor_plot_controls"), downloadButton("download_cor", "Download Correlation Plot (High-Res)")),
        tabPanel("Boruta Features", verbatimTextOutput("boruta_features"), plotlyOutput("boruta_plot", height = "600px") %>% withSpinner(),
                 h4("Settings & Download"), uiOutput("boruta_plot_controls"), downloadButton("download_boruta", "Download Boruta Plot (High-Res)")),
        tabPanel("Model Results",
                 h4("Training Set Metrics (Calculated on Training Data)"),
                 tableOutput("model_results_train") %>% withSpinner(),
                 h4("Test Set Metrics (Calculated on Test Data)"),
                 tableOutput("model_results_test") %>% withSpinner(),
                 h4("Cross-Validation Metrics (Average over Folds for Best Tune)"),
                 tableOutput("model_results_cv") %>% withSpinner()
        ),
        tabPanel("Training Time", plotlyOutput("timing_plot") %>% withSpinner(),
                 h4("Settings & Download"), uiOutput("timing_plot_controls"), downloadButton("download_timing", "Download Timing Plot (High-Res)")),
        tabPanel("Actual vs Predicted",
                 uiOutput("model_selection_ap"), # Model selection moved here
                 plotlyOutput("scatter_plot", height = "600px") %>% withSpinner(),
                 h4("Settings & Download"), uiOutput("scatter_plot_controls"), downloadButton("download_scatter", "Download Scatter Plot (High-Res)")),
        tabPanel("Predicted vs Residual Plot",
                 uiOutput("model_selection_pr"), # Model selection moved here
                 plotlyOutput("residual_plot", height = "600px") %>% withSpinner(),
                 h4("Settings & Download"), uiOutput("residual_plot_controls"), downloadButton("download_residual", "Download Residual Plot (High-Res)")),
        tabPanel("Explainable Models",
                 h4("Settings & Download for Explainable Models"), # Combined settings for LM/rpart
                 tabsetPanel(
                   tabPanel("Linear Regression",
                            uiOutput("lm_equation_output"),
                            plotOutput("lm_coef_plot") %>% withSpinner(),
                            uiOutput("lm_coef_plot_controls"), # Controls for LM plot
                            downloadButton("download_lm_coef", "Download LM Coef Plot (High-Res)")),
                   tabPanel("Decision Tree",
                            plotOutput("rpart_tree_plot", height = "600px") %>% withSpinner(),
                            uiOutput("rpart_tree_plot_controls"), # Controls for rpart plot
                            downloadButton("download_rpart_tree", "Download Decision Tree Plot (High-Res)"))
                 )
        ),
        tabPanel("Comparison with Thesis",
                 uiOutput("model_selection_comp"), # Model selection moved here
                 plotlyOutput("comparison_plot", height = "500px"),
                 tableOutput("comparison_table"),
                 h4("Settings & Download"), uiOutput("comparison_plot_controls"), downloadButton("download_comparison", "Download Comparison Plot (High-Res)")
        ),
        tabPanel("Reporting & Export",
                 h4("Generate Analysis Report"),
                 actionButton("generate_pdf_report", "Generate PDF Report", class = "btn btn-info"),
                 actionButton("generate_html_report", "Generate HTML Report", class = "btn btn-info"),
                 hr(),
                 h4("Export Data and Metrics"),
                 downloadButton("download_cleaned_data", "Download Cleaned Data (CSV)"),
                 downloadButton("download_all_metrics", "Download All Model Metrics (CSV)")
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  
  # Fixed calibration data
  calibration_data <- data.frame(
    Experiment = c("D-001-I", "E-001-I", "E-001-II", "E-002-I", "E-002-II", "E-003-I", "E-003-II"),
    n_value = c(3.122, 2.832, 3.769, 3.060, 3.868, 3.160, 3.635),
    stringsAsFactors = FALSE
  )
  
  # Fixed specimen width data
  specimen_data <- data.frame(
    Experiment = c("D-002", "E-001", "E-002", "E-003"),
    w_value = c(24.82, 24.87, 24.93, 24.85),
    stringsAsFactors = FALSE
  )
  
  # Reactive value to store Boruta results
  boruta_results <- reactiveVal(NULL)
  predictors_fed_to_boruta <- reactiveVal(NULL)
  features_used_for_modeling <- reactiveVal(NULL)
  fits <- reactiveVal(list())
  df_clean_reactive <- reactiveVal(NULL)
  outlier_summary_reactive <- reactiveVal(NULL)
  all_model_results_reactive <- reactiveVal(list())
  
  # For report generation
  timing_results_reactive <- reactiveVal(NULL)
  test_predictions_reactive <- reactiveVal(NULL)
  test_data_reactive <- reactiveVal(NULL)
  
  # Reactive values for plot settings
  plot_settings <- reactiveValues(
    hist = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", fill_color = "#4682B4", bins = 30, alpha = 0.7, base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    box = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", fill_color = "#FF6347", alpha = 0.7, base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    cor = list(title_size = 14, tl_cex = 1.1, cl_cex = 1.1, number_cex = 1.3), # Specific to corrplot
    boruta = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    timing = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", bar_fill_color = "#6A5ACD", text_label_size = 4, base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    scatter = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", point_alpha = 0.6, line_color = "red", base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    residual = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", point_alpha = 0.6, line_color = "red", base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    lm_coef = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", base_size = 12, background_color = "#FFFFFF", legend_text_size = 10),
    rpart_tree = list(title_size = 14, tweak = 1.2, box_palette = "RdBu", split_cex = 1.2), # Specific to rpart.plot
    comparison = list(title_size = 14, axis_title_size = 12, axis_text_size = 10, font_family = "sans", point_alpha = 0.6, line_color = "black", base_size = 12, background_color = "#FFFFFF", legend_text_size = 10)
  )
  
  # Helper function to apply common ggplot themes
  apply_ggplot_theme <- function(p, settings) {
    p +
      theme_minimal(base_size = settings$base_size) +
      theme(
        plot.title = element_blank(), # Removed title from all plots
        axis.title = element_text(size = settings$axis_title_size, face = "bold", family = settings$font_family),
        axis.text = element_text(size = settings$axis_text_size, family = settings$font_family),
        legend.text = element_text(size = settings$legend_text_size, family = settings$font_family),
        legend.title = element_text(size = settings$legend_text_size, face = "bold", family = settings$font_family),
        text = element_text(family = settings$font_family),
        panel.background = element_rect(fill = settings$background_color, colour = NA),
        plot.background = element_rect(fill = settings$background_color, colour = NA)
      )
  }
  
  # Extract experiment ID from file name
  extract_experiment_id <- function(file_name) {
    gsub("-processed\\.csv$", "", basename(file_name))
  }
  
  data_raw <- reactive({
    req(input$file)
    df <- tryCatch(read.csv(input$file$datapath, stringsAsFactors = FALSE), error = function(e) NULL)
    if (is.null(df)) {
      showNotification("Error reading file. Please ensure it's a valid CSV.", type = "error")
      return(NULL)
    }
    
    # Convert columns to numeric if possible
    df[] <- lapply(df, function(col) {
      if (is.character(col)) {
        suppressWarnings(num_col <- as.numeric(gsub(",", ".", col)))
        if(sum(!is.na(num_col)) / length(col) > 0.5) return(num_col)
        suppressWarnings(num_col <- as.numeric(col))
        if(sum(!is.na(num_col)) / length(col) > 0.5) return(num_col)
      } else if (is.factor(col)) {
        suppressWarnings(num_col <- as.numeric(as.character(col)))
        if(sum(!is.na(num_col)) / length(col) > 0.5) return(num_col)
      }
      return(col)
    })
    
    # 1. NA CLEANING
    critical_columns <- c("N", "F", "d", "a", "dadN", "G_max", "Delta_sqrt.G.", "R",
                          "Cyclic_Energy", "Monotonic_Energy", "Total_Energy")
    
    existing_columns <- critical_columns[critical_columns %in% names(df)]
    
    if (length(existing_columns) > 0) {
      df <- df[complete.cases(df[, existing_columns]), ]
      
      if (nrow(df) == 0) {
        showNotification("All rows removed after NA cleaning. Please check your data.", type = "warning")
        return(NULL)
      }
    }
    
    # Extract experiment ID from file name
    file_name <- input$file$name
    experiment_id <- extract_experiment_id(file_name)
    df$Experiment_ID <- experiment_id
    
    # Merge calibration data
    df <- merge(df, calibration_data, by.x = "Experiment_ID", by.y = "Experiment", all.x = TRUE)
    
    # Extract base experiment
    df$Base_Experiment <- substr(df$Experiment_ID, 1, 5)
    
    # Merge specimen width data
    df <- merge(df, specimen_data, by.x = "Base_Experiment", by.y = "Experiment", all.x = TRUE)
    
    # Calculate alpha and beta for each experiment
    coefs <- df %>%
      group_by(Experiment_ID) %>%
      do({
        valid_rows <- !is.na(.$a) & !is.na(.$N) & .$a > 0 & .$N > 0
        if (sum(valid_rows) >= 2) {
          model <- lm(log(a) ~ log(N), data = .[valid_rows, ])
          data.frame(alpha = exp(coef(model)[1]), beta = coef(model)[2])
        } else {
          data.frame(alpha = NA, beta = NA)
        }
      }) %>%
      ungroup()
    
    # Merge coefficients back
    df <- merge(df, coefs, by = "Experiment_ID", all.x = TRUE)
    
    # Calculate theoretical values
    df$dadN_theoretical <- with(df, alpha * beta * N^(beta - 1))
    df$Total_Energy_theoretical <- with(df, Cyclic_Energy + Monotonic_Energy)
    df$G_max_theoretical <- with(df, (n_value * F * d) / (2 * w_value * a))
    
    df
  })
  
  predict_from_pascoe_dadN <- function(G_max, Delta_sqrt.G., R) {
    C <- 2.3e-5
    a <- 1.15
    b <- 0.85
    c <- 0.25
    
    dadN_theoretical <- C * (G_max)^a * (Delta_sqrt.G.)^b * (1 - R)^c
    return(dadN_theoretical)
  }
  
  predict_from_pascoe_Total_Energy <- function(N, a_val, F, d, C_val, R) {
    C_te <- 0.01
    n_exp <- 0.5
    a_exp <- 1.0
    f_exp <- 0.7
    d_exp <- 0.3
    c_exp <- 0.1
    r_exp <- 0.2
    
    if (any(is.na(c(N, a_val, F, d, C_val, R)))) {
      return(rep(NA, length(N)))
    }
    
    total_energy_theoretical <- C_te * (N)^n_exp * (a_val)^a_exp * (F)^f_exp * (d)^d_exp * (C_val)^c_exp * (R)^r_exp
    return(total_energy_theoretical)
  }
  
  predict_from_pascoe_G_max <- function(a_val, F) {
    C_gm <- 10
    a_exp_gm <- 0.9
    f_exp_gm <- 0.6
    
    if (any(is.na(c(a_val, F)))) {
      return(rep(NA, length(a_val)))
    }
    
    g_max_theoretical <- C_gm * (a_val)^a_exp_gm * (F)^f_exp_gm
    return(g_max_theoretical)
  }
  
  comparison_data <- reactive({
    req(input$target_var)
    df_clean <- df_clean_reactive()
    if (is.null(df_clean)) return(NULL)
    
    set.seed(input$seed)
    train_index <- createDataPartition(df_clean[[input$target_var]], p = input$split_ratio/100, list = FALSE)
    test_data <- df_clean[-train_index, ]
    
    models <- fits()
    if (is.null(models)) models <- list()
    
    n_test <- nrow(test_data)
    
    ml_preds_list <- lapply(names(models), function(model_name) {
      if (!is.null(models[[model_name]])) {
        pred <- tryCatch(predict(models[[model_name]], newdata = test_data),
                         error = function(e) {
                           message(paste("Prediction error for model", model_name, ":", e$message)) # Hata mesajını konsola yazdır
                           return(rep(NA, n_test))
                         })
        if (length(pred) != n_test) pred <- rep(NA, n_test)
        
        data.frame(
          Model_Type = model_name,
          Actual = test_data[[input$target_var]],
          Predicted = pred,
          stringsAsFactors = FALSE
        )
      } else {
        data.frame(
          Model_Type = model_name,
          Actual = test_data[[input$target_var]],
          Predicted = rep(NA, n_test),
          stringsAsFactors = FALSE
        )
      }
    })
    
    theoretical_col <- paste0(input$target_var, "_theoretical")
    theoretical_preds <- rep(NA, n_test) 
    if (theoretical_col %in% names(test_data) && is.numeric(test_data[[theoretical_col]])) {
      theoretical_preds <- test_data[[theoretical_col]]
    } else {
      # message(paste("Warning: Theoretical column '", theoretical_col, "' not found or not numeric in test data. Theoretical predictions will be NA.", sep=""))
    }
    
    
    theoretical_preds_df <- data.frame(
      Model_Type = "Theoretical Model",
      Actual = test_data[[input$target_var]],
      Predicted = theoretical_preds,
      stringsAsFactors = FALSE
    )
    
    # Bind rows, filtering out any completely NA rows from ml_preds_list first to avoid issues
    all_preds_df <- bind_rows(ml_preds_list)
    final_df <- bind_rows(all_preds_df, theoretical_preds_df)
    
    # Ensure 'Predicted' and 'Actual' are numeric and handle NAs correctly
    final_df$Predicted <- as.numeric(final_df$Predicted)
    final_df$Actual <- as.numeric(final_df$Actual)
    
    # Remove rows where either Actual or Predicted is NA for proper plotting
    final_df <- final_df %>% filter(!is.na(Actual) & !is.na(Predicted))
    
    return(final_df)
  })
  
  
  output$target_selector <- renderUI({
    req(data_raw())
    df <- data_raw()
    allowed_targets <- c("dadN", "Total_Energy", "G_max")
    available_allowed_targets <- intersect(allowed_targets, names(df)[sapply(df, is.numeric)])
    
    validate(
      need(length(available_allowed_targets) > 0, paste("No suitable numeric columns found for target variable selection (needs to be one of:", paste(allowed_targets, collapse = ", "), "). Please upload a dataset with these columns."))
    )
    
    selectInput("target_var", "Select Target Variable:", choices = available_allowed_targets)
  })
  
  output$boxplot_feature_selector <- renderUI({
    req(data_raw(), input$target_var)
    df <- data_raw()
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    default_selection <- setdiff(numeric_cols, input$target_var)
    
    pickerInput(
      inputId = "boxplot_features",
      label = "Select Features for Boxplots:",
      choices = numeric_cols,
      selected = default_selection,
      options = list(`actions-box` = TRUE, `live-search` = TRUE),
      multiple = TRUE
    )
  })
  
  # EDA Outputs
  output$missing_summary <- renderPrint({
    req(data_raw())
    df <- data_raw()
    cat("Missing Values Summary:\n")
    print(colSums(is.na(df)))
  })
  
  output$outlier_summary <- renderPrint({
    req(outlier_summary_reactive())
    outlier_summary_reactive()
  })
  
  output$histograms <- renderPlot({
    req(data_raw())
    df <- data_raw()
    num_df <- df %>% select(where(is.numeric))
    validate(need(ncol(num_df) > 0, "No numeric columns available for histogram plots."))
    
    df_long <- num_df %>% pivot_longer(everything(), names_to = "Feature", values_to = "Value")
    p <- ggplot(df_long, aes(x = Value)) +
      geom_histogram(bins = plot_settings$hist$bins, fill = plot_settings$hist$fill_color, alpha = plot_settings$hist$alpha) +
      facet_wrap(~ Feature, scales = "free") +
      labs(x = "Value", y = "Count") # Removed title
    apply_ggplot_theme(p, plot_settings$hist)
  })
  
  output$boxplots <- renderPlot({
    req(data_raw(), input$boxplot_features)
    df <- data_raw()
    selected_features <- input$boxplot_features
    
    validate(need(length(selected_features) > 0, "Please select at least one feature for boxplots."))
    
    cols_to_plot <- selected_features[selected_features %in% names(df) & sapply(df[selected_features], is.numeric)]
    
    validate(need(length(cols_to_plot) > 0, "No selected numeric columns available for boxplots after filtering."))
    
    num_df <- df %>% select(any_of(cols_to_plot))
    
    df_long <- num_df %>% pivot_longer(everything(), names_to = "Feature", values_to = "Value")
    p <- ggplot(df_long, aes(x = Feature, y = Value)) +
      geom_boxplot(fill = plot_settings$box$fill_color, alpha = plot_settings$box$alpha) +
      labs(x = "Feature", y = "Value") + # Removed title
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    apply_ggplot_theme(p, plot_settings$box)
  })
  
  output$data_preview <- renderDT({
    req(data_raw())
    datatable(data_raw(), options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # INTERACTIVE Correlation Plot using Plotly
  output$cor_plot <- renderPlotly({
    req(data_raw(), input$target_var)
    df <- data_raw()
    target <- input$target_var
    
    potential_cor_vars <- switch(target,
                                 "dadN" = c("G_max", "R", "Delta_sqrt.G."),
                                 "Total_Energy" = c("N", "a", "F", "d", "C", "R"),
                                 "G_max" = c("a", "F"),
                                 NULL
    )
    
    validate(
      need(!is.null(potential_cor_vars) && length(potential_cor_vars) > 0, paste("No predefined predictors for target:", target, "to generate correlation plot."))
    )
    
    cols_needed <- c(target, potential_cor_vars)
    
    missing_cols <- setdiff(cols_needed, names(df))
    validate(
      need(length(missing_cols) == 0, paste("Missing required columns for correlation plot for target", target, ":", paste(missing_cols, collapse = ", ")))
    )
    
    df_subset <- df[, cols_needed, drop = FALSE]
    numeric_subset <- df_subset %>% select(where(is.numeric))
    
    validate(
      need(ncol(numeric_subset) == length(cols_needed), paste("Some required columns for correlation plot for target", target, "are not numeric:", paste(setdiff(cols_needed, names(numeric_subset)), collapse = ", ")))
    )
    
    df_subset_clean <- na.omit(numeric_subset)
    
    validate(
      need(ncol(df_subset_clean) >= 2, paste("Correlation plot requires at least 2 numeric columns (target + predictor) after cleaning for target", target, ".")),
      need(nrow(df_subset_clean) > 1, paste("Not enough complete cases for correlation plot after cleaning for target", target, "."))
    )
    
    cor_matrix <- cor(df_subset_clean, use = "pairwise.complete.obs")
    cor_matrix[!is.finite(cor_matrix)] <- NA
    
    # Convert corrplot to a ggplot object, then to plotly
    cor_df <- as.data.frame(cor_matrix)
    cor_df$Var1 <- rownames(cor_df)
    cor_long <- cor_df %>%
      pivot_longer(cols = -Var1, names_to = "Var2", values_to = "Correlation") %>%
      # Keep only upper triangle
      filter(as.integer(factor(Var1, levels = rownames(cor_matrix))) <= as.integer(factor(Var2, levels = colnames(cor_matrix))))
    
    p <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = Correlation,
                              text = paste("Var1:", Var1, "<br>Var2:", Var2, "<br>Corr:", round(Correlation, 2)))) +
      geom_tile(color = "white") +
      geom_text(aes(label = round(Correlation, 2)), color = "black", size = plot_settings$cor$number_cex * 3) + # number_cex kontrolünden boyutu alsın
      scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                           midpoint = 0, limit = c(-1,1), space = "Lab",
                           name="Correlation") +
      coord_fixed() +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
            axis.title = element_blank(),
            plot.title = element_blank(), 
            legend.position = "bottom")
    
    ggplotly(p, tooltip = "text") %>%
      layout(
        xaxis = list(tickfont = list(size = plot_settings$cor$tl_cex * 10)), # Adjust based on cex
        yaxis = list(tickfont = list(size = plot_settings$cor$tl_cex * 10))
      ) %>%
      config(displaylogo = FALSE) # Remove Plotly logo
  })
  
  # INTERACTIVE Boruta Plot using Plotly
  output$boruta_plot <- renderPlotly({
    req(boruta_results())
    boruta_res <- boruta_results()
    
    importance_df <- attStats(boruta_res) %>%
      mutate(Feature = rownames(attStats(boruta_res)),
             Decision = factor(decision, levels = c("Confirmed", "Tentative", "Rejected")))
    
    p <- ggplot(importance_df, aes(x = reorder(Feature, meanImp), y = meanImp, fill = Decision,
                                   text = paste("Feature:", Feature, "<br>Importance:", round(meanImp, 2), "<br>Decision:", Decision))) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(x = "Feature", y = "Mean Importance") + 
      scale_fill_manual(values = c("Confirmed" = "green", "Tentative" = "orange", "Rejected" = "red"))
    
    # Apply ggplot theme settings (not all directly transferable to plotly, but some basic ones like font will apply via layout)
    p_themed <- apply_ggplot_theme(p, plot_settings$boruta)
    
    ggplotly(p_themed, tooltip = "text") %>%
      layout(
        xaxis = list(title = list(font = list(size = plot_settings$boruta$axis_title_size))),
        yaxis = list(title = list(font = list(size = plot_settings$boruta$axis_title_size))),
        font = list(family = plot_settings$boruta$font_family)
      ) %>%
      config(displaylogo = FALSE) # Remove Plotly logo
  })
  
  observeEvent(input$run, {
    req(data_raw(), input$target_var, input$models)
    
    boruta_results(NULL)
    predictors_fed_to_boruta(NULL)
    features_used_for_modeling(NULL)
    fits(list())
    df_clean_reactive(NULL)
    outlier_summary_reactive(NULL)
    timing_results_reactive(NULL)
    test_predictions_reactive(NULL)
    test_data_reactive(NULL)
    
    df <- data_raw()
    target <- input$target_var
    
    potential_boruta_predictors <- switch(target,
                                          "dadN" = c("G_max", "R", "Delta_sqrt.G."),
                                          "Total_Energy" = c("N", "a", "F", "d", "C", "R"),
                                          "G_max" = c("a", "F"),
                                          NULL
    )
    
    if (is.null(potential_boruta_predictors) || length(potential_boruta_predictors) == 0) {
      showNotification(paste("Internal Error: Predictors not defined or empty for target:", target), type = "error")
      output$boruta_features <- renderPrint({ "Analysis skipped: Predictors not defined internally." })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      return()
    }
    
    missing_initial_predictors <- setdiff(potential_boruta_predictors, names(df))
    if (length(missing_initial_predictors) > 0) {
      showNotification(paste("Missing required predictor columns in uploaded data for target '", target, "': ", paste(missing_initial_predictors, collapse = ", "), ". Please upload a dataset with these columns."), type = "error")
      output$boruta_features <- renderPrint({ paste("Analysis skipped: Missing predictor columns for", input$target_var, ": ", paste(missing_initial_predictors, collapse = ", ")) })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      return()
    }
    
    are_potential_numeric <- sapply(df[, potential_boruta_predictors, drop = FALSE], is.numeric)
    if (any(!are_potential_numeric)) {
      non_numeric_features <- potential_boruta_predictors[!are_potential_numeric]
      showNotification(paste("Selected predictor(s) for target '", target, "' are not numeric:", paste(non_numeric_features, collapse = ", "), ". Please ensure these columns are numeric."), type = "error")
      output$boruta_features <- renderPrint({ paste("Analysis skipped: Non-numeric predictors for", input$target_var, ": ", paste(non_numeric_features, collapse = ", ")) })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) }) # No title, no logo
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      return()
    }
    
    cols_for_cleaning <- c(target, potential_boruta_predictors)
    df_processed <- df[, cols_for_cleaning, drop = FALSE]
    
    outlier_count_before <- 0
    outlier_summary_text <- "Outlier Management:\n"
    
    if (input$enable_outlier_mgt) {
      outlier_summary_text <- paste0(outlier_summary_text, "  Enabled with Z-score threshold: ", input$zscore_threshold, "\n")
      outlier_summary_text <- paste0(outlier_summary_text, "  Method: ", input$outlier_method, "\n")
      
      initial_rows <- nrow(df_processed)
      outliers_detected_per_col <- list()
      
      for (col_name in names(df_processed)) {
        if (is.numeric(df_processed[[col_name]])) {
          mean_val <- mean(df_processed[[col_name]], na.rm = TRUE)
          sd_val <- sd(df_processed[[col_name]], na.rm = TRUE)
          
          if (sd_val > 0) {
            z_scores <- abs((df_processed[[col_name]] - mean_val) / sd_val)
            is_outlier <- z_scores > input$zscore_threshold
            
            if (any(is_outlier, na.rm = TRUE)) {
              outlier_indices <- which(is_outlier)
              outliers_detected_per_col[[col_name]] <- length(outlier_indices)
              outlier_count_before <- outlier_count_before + length(outlier_indices)
              
              if (input$outlier_method == "remove") {
                df_processed <- df_processed[!is_outlier, ]
              } else if (input$outlier_method == "cap") {
                upper_bound <- mean_val + input$zscore_threshold * sd_val
                lower_bound <- mean_val - input$zscore_threshold * sd_val
                df_processed[[col_name]][df_processed[[col_name]] > upper_bound] <- upper_bound
                df_processed[[col_name]][df_processed[[col_name]] < lower_bound] <- lower_bound
              } else if (input$outlier_method == "na") {
                df_processed[[col_name]][is_outlier] <- NA
              }
            }
          }
        }
      }
      
      outlier_summary_text <- paste0(outlier_summary_text, "\nOutliers detected per column (before handling):\n")
      if (length(outliers_detected_per_col) > 0) {
        for (col_name in names(outliers_detected_per_col)) {
          outlier_summary_text <- paste0(outlier_summary_text, "  ", col_name, ": ", outliers_detected_per_col[[col_name]], "\n")
        }
      } else {
        outlier_summary_text <- paste0(outlier_summary_text, "  No outliers detected in selected numeric columns.\n")
      }
      
      rows_after_outlier_removal <- nrow(df_processed)
      if (input$outlier_method == "remove") {
        outlier_summary_text <- paste0(outlier_summary_text, "\nRows removed due to outliers: ", initial_rows - rows_after_outlier_removal, "\n")
      }
      
    } else {
      outlier_summary_text <- paste0(outlier_summary_text, "  Outlier management is disabled.\n")
    }
    
    outlier_summary_reactive(outlier_summary_text)
    
    df_clean <- na.omit(df_processed)
    df_clean_reactive(df_clean)
    
    if (nrow(df_clean) == 0) {
      showNotification(paste("Data contains no complete cases for target and specified predictors after NA and/or outlier removal for target '", target, "'. Cannot run analysis."), type = "warning")
      output$boruta_features <- renderPrint({ "Analysis skipped: No data after NA/outlier removal for specified predictors." })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      boruta_results(NULL)
      predictors_fed_to_boruta(NULL)
      features_used_for_modeling(character(0))
      return()
    }
    
    if (!is.numeric(df_clean[[target]])) {
      showNotification(paste("Target variable '", target, "' is not numeric after data cleaning. Cannot train models."), type = "error")
      output$boruta_features <- renderPrint({ paste("Analysis skipped: Target variable '", target, "' is not numeric.") })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      boruta_results(NULL)
      predictors_fed_to_boruta(NULL)
      features_used_for_modeling(character(0))
      return()
    }
    
    set.seed(input$seed)
    train_index <- createDataPartition(df_clean[[target]], p = input$split_ratio/100, list = FALSE)
    train_data <- df_clean[train_index, ]
    test_data <- df_clean[-train_index, ]
    
    actual_boruta_predictors_in_train <- intersect(potential_boruta_predictors, names(train_data))
    
    predictors_fed_to_boruta(actual_boruta_predictors_in_train)
    
    final_features_determined <- character(0)
    
    if (length(actual_boruta_predictors_in_train) == 0) {
      showNotification("Boruta did not confirm any features. Using all specified predictors available in the training set.", type = "warning")
      # Clear plots/results related to modeling if no features
      output$boruta_features <- renderPrint({ "No specified predictors available in the training set after cleaning and splitting. Skipping Boruta and model training." })
      output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      boruta_results(NULL)
      features_used_for_modeling(character(0))
      return()
    } else {
      boruta_formula <- as.formula(paste(target, "~", paste(actual_boruta_predictors_in_train, collapse = "+")))
      
      boruta_res <- tryCatch({
        Boruta(boruta_formula, data = train_data, doTrace = 0, maxRuns = 100)
      }, error = function(e) {
        showNotification(paste("Error running Boruta:", e$message), type = "error")
        output$boruta_features <- renderPrint({ paste("Boruta skipped due to error:", e$message) })
        output$boruta_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
        output$model_results_train <- renderTable({ data.frame() })
        output$model_results_test <- renderTable({ data.frame() })
        output$model_results_cv <- renderTable({ data.frame() })
        output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
        output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
        output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
        output$lm_equation_output <- renderUI({ HTML("") })
        output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
        output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
        return(NULL)
      })
      
      boruta_results(boruta_res)
      
      if (!is.null(boruta_res)) {
        final_features_determined <- getSelectedAttributes(boruta_res, withTentative = FALSE)
        
        if (length(final_features_determined) == 0) {
          showNotification("Boruta did not confirm any features. Using all specified predictors available in the training set.", type = "warning")
          final_features_determined <- actual_boruta_predictors_in_train
        }
      } else {
        final_features_determined <- character(0)
      }
    }
    features_used_for_modeling(final_features_determined)
    
    if (length(final_features_determined) == 0) {
      showNotification("No predictor features available after Boruta selection or fallback. Cannot train models.", type = "warning")
      output$model_results_train <- renderTable({ data.frame() })
      output$model_results_test <- renderTable({ data.frame() })
      output$model_results_cv <- renderTable({ data.frame() })
      output$timing_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$scatter_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$residual_plot <- renderPlotly({ plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE) })
      output$lm_equation_output <- renderUI({ HTML("") })
      output$lm_coef_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      output$rpart_tree_plot <- renderPlot({ plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Analysis skipped") })
      return()
    }
    
    control <- trainControl(method = "cv", number = input$cv_folds, savePredictions = "final")
    
    train_results_list <- list()
    test_results_list <- list()
    cv_results_list <- list()
    timing_list <- list()
    pred_all_test <- list()
    
    fits(list())
    
    model_formula <- as.formula(paste(target, "~", paste(final_features_determined, collapse = "+")))
    
    for (model_name in input$models) { # Loop over selected models
      cat("Training model:", model_name, "...\n")
      set.seed(input$seed)
      t0 <- Sys.time()
      
      # Removed nnet and earth specific preProcess here, as they are removed from models.
      fit <- tryCatch({
        train(model_formula, data = train_data, method = model_name, trControl = control)
      }, error = function(e) {
        showNotification(paste("Error training", model_name, ":", e$message), type = "error")
        return(NULL)
      })
      
      t1 <- Sys.time()
      duration <- as.numeric(difftime(t1, t0, units = "secs"))
      timing_list[[model_name]] <- duration
      
      if (!is.null(fit)) {
        current_fits <- fits()
        current_fits[[model_name]] <- fit
        fits(current_fits)
        
        train_data_eval <- train_data
        
        if(nrow(train_data_eval) > 0) {
          pred_train <- tryCatch(predict(fit, newdata = train_data_eval, na.action = na.omit),
                                 error = function(e) { showNotification(paste("Error predicting on training data for", model_name, ":", e$message), type = "error"); return(NULL)})
          if (!is.null(pred_train) && length(pred_train) == nrow(train_data_eval)) {
            valid_indices_train <- which(!is.na(pred_train) & is.finite(pred_train) & !is.na(train_data_eval[[target]]) & is.finite(train_data_eval[[target]]))
            if (length(valid_indices_train) > 0) {
              actual_train <- train_data_eval[[target]][valid_indices_train]
              predicted_train <- pred_train[valid_indices_train]
              
              rmse_train <- suppressWarnings(Metrics::rmse(predicted_train, actual_train))
              rsq_train <- suppressWarnings(caret::R2(predicted_train, actual_train))
              mae_train <- suppressWarnings(Metrics::mae(predicted_train, actual_train))
              mape_train <- suppressWarnings(Metrics::mape(predicted_train, actual_train))
              mdae_train <- suppressWarnings(Metrics::mdae(predicted_train, actual_train))
              rmsle_train <- suppressWarnings(Metrics::rmsle(predicted_train, actual_train))
              
              train_results_list[[model_name]] <- data.frame(Model = model_name,
                                                             RMSE = rmse_train,
                                                             Rsquared = rsq_train,
                                                             MAE = mae_train,
                                                             MAPE = mape_train,
                                                             MdAE = mdae_train,
                                                             RMSLE = rmsle_train,
                                                             stringsAsFactors = FALSE)
            } else {
              showNotification(paste("Could not calculate training metrics for", model_name, ": No valid training predictions or target values after filtering NAs/Infs."), type = "warning")
              train_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
            }
          } else {
            showNotification(paste("Prediction on training data failed or returned incorrect length for", model_name), type = "error")
            train_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
          }
        } else {
          showNotification(paste("Skipping training metrics for", model_name, ": Training data is empty."), type = "warning")
          train_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
        }
        cols_for_eval <- c(final_features_determined, target)
        cols_for_eval <- cols_for_eval[cols_for_eval %in% names(test_data)]
        if (length(cols_for_eval) < 2 || !(target %in% cols_for_eval)) {
          showNotification(paste("Internal Error: Cannot prepare test data for evaluation for model", model_name, "(missing target or selected features)."), type = "error")
          test_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
          pred_all_test[[model_name]] <- NULL
          next
        }
        test_data_eval <- test_data[, cols_for_eval, drop = FALSE]
        if(nrow(test_data_eval) > 0) {
          pred_test <- tryCatch(predict(fit, newdata = test_data_eval, na.action = na.omit), error = function(e) { showNotification(paste("Error predicting on test data for", model_name, ":", e$message), type = "error"); return(NULL)})
          if (!is.null(pred_test) && length(pred_test) == nrow(test_data_eval)) {
            valid_indices_test <- which(!is.na(pred_test) & is.finite(pred_test) & !is.na(test_data_eval[[target]]) & is.finite(test_data_eval[[target]]))
            if (length(valid_indices_test) > 0) {
              actual_test <- test_data_eval[[target]][valid_indices_test]
              predicted_test <- pred_test[valid_indices_test]
              rmse_test <- suppressWarnings(Metrics::rmse(predicted_test, actual_test))
              rsq_test <- suppressWarnings(caret::R2(predicted_test, actual_test))
              mae_test <- suppressWarnings(Metrics::mae(predicted_test, actual_test))
              mape_test <- suppressWarnings(Metrics::mape(predicted_test, actual_test))
              mdae_test <- suppressWarnings(Metrics::mdae(predicted_test, actual_test))
              rmsle_test <- suppressWarnings(Metrics::rmsle(predicted_test, actual_test))
              
              test_results_list[[model_name]] <- data.frame(Model = model_name,
                                                            RMSE = rmse_test,
                                                            Rsquared = rsq_test,
                                                            MAE = mae_test,
                                                            MAPE = mape_test,
                                                            MdAE = mdae_test,
                                                            RMSLE = rmsle_test,
                                                            stringsAsFactors = FALSE)
              pred_all_test[[model_name]] <- pred_test
            } else {
              showNotification(paste("Could not calculate test metrics for", model_name, ": No valid test predictions or target values after filtering NAs/Infs."), type = "warning")
              test_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
              pred_all_test[[model_name]] <- rep(NA, nrow(test_data_eval))
            }
          } else {
            showNotification(paste("Prediction on test data failed or returned incorrect length for", model_name), type = "error")
            test_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
            pred_all_test[[model_name]] <- rep(NA, nrow(test_data_eval))
          }
        } else {
          showNotification(paste("Skipping test metrics for", model_name, ": Test data subset for evaluation is empty."), type = "warning")
          test_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
          pred_all_test[[model_name]] <- rep(NA, nrow(test_data_eval))
        }
        results_table <- fit$results
        if (is.null(fit$bestTune) || ncol(fit$bestTune) == 0 || nrow(fit$bestTune) == 0) {
          best_cv_metrics <- results_table[1, ]
        } else {
          suppressWarnings({ merged_results <- merge(results_table, fit$bestTune, by = names(fit$bestTune), all = FALSE) })
          if (nrow(merged_results) > 0) {
            best_cv_metrics <- merged_results[1, ]
          } else {
            best_tune_values <- as.list(fit$bestTune[1,])
            match_row_index <- which(apply(results_table[, names(best_tune_values), drop = FALSE], 1, function(row) all(unlist(row) == unlist(best_tune_values))))
            if (length(match_row_index) > 0) {
              best_cv_metrics <- results_table[match_row_index[1], ]
            } else {
              showNotification(paste("Warning: Could not find specific CV results for the best tune for model", model_name, ". Showing the first row of CV results instead."), type = "warning")
              if (nrow(results_table) > 0) {
                best_cv_metrics <- results_table[1, ]
              } else {
                best_cv_metrics <- data.frame(RMSE = NA, Rsquared = NA, RSq = NA)
              }
            }
          }
        }
        model_cv_row <- data.frame(Model = model_name, stringsAsFactors = FALSE)
        if ("RMSE" %in% names(best_cv_metrics)) {
          model_cv_row$RMSE_CV = best_cv_metrics$RMSE
        } else {
          model_cv_row$RMSE_CV = NA
        }
        if ("Rsquared" %in% names(best_cv_metrics)) {
          model_cv_row$Rsquared_CV = best_cv_metrics$Rsquared
        } else if ("RSq" %in% names(best_cv_metrics)) {
          model_cv_row$Rsquared_CV = best_cv_metrics$RSq
        } else {
          model_cv_row$Rsquared_CV = NA
        }
        cv_results_list[[model_name]] <- model_cv_row
      } else {
        train_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
        test_results_list[[model_name]] <- data.frame(Model = model_name, RMSE = NA, Rsquared = NA, MAE = NA, MAPE = NA, MdAE = NA, RMSLE = NA, stringsAsFactors = FALSE)
        cv_results_list[[model_name]] <- data.frame(Model = model_name, RMSE_CV = NA, Rsquared_CV = NA, stringsAsFactors = FALSE)
        pred_all_test[[model_name]] <- NULL
      }
    }
    train_results_df <- bind_rows(train_results_list)
    test_results_df <- bind_rows(test_results_list)
    cv_results_df <- bind_rows(cv_results_list)
    timing_df <- data.frame(Model = names(timing_list), Time = unlist(timing_list), stringsAsFactors = FALSE)
    
    # Store all results for export
    all_model_results_reactive(list(
      train = train_results_df,
      test = test_results_df,
      cv = cv_results_df
    ))
    
    # Store additional data for reports
    timing_results_reactive(timing_df)
    test_predictions_reactive(pred_all_test)
    test_data_reactive(test_data)
    
    # Update available models for plot selection (after models are trained)
    updatePickerInput(session, "selected_models_ap", choices = names(pred_all_test), selected = names(pred_all_test))
    updatePickerInput(session, "selected_models_pr", choices = names(pred_all_test), selected = names(pred_all_test))
    updatePickerInput(session, "selected_models_comp", choices = c("Theoretical Model", names(pred_all_test)), selected = c("Theoretical Model", names(pred_all_test)))
    
    
    format_metrics_df <- function(df) {
      if (nrow(df) == 0) return(df)
      num_cols <- sapply(df, is.numeric)
      df[, num_cols] <- lapply(df[, num_cols, drop = FALSE], function(col) { sprintf("%.6g", col) })
      return(df)
    }
    
    format_cv_metrics_df <- function(df) {
      if (nrow(df) == 0) return(df)
      num_cols <- sapply(df, is.numeric)
      df[, num_cols] <- lapply(df[, num_cols, drop = FALSE], function(col) { sprintf("%.6g", col) })
      return(df)
    }
    
    train_results_df_formatted <- format_metrics_df(train_results_df)
    test_results_df_formatted <- format_metrics_df(test_results_df)
    cv_results_df_formatted <- format_cv_metrics_df(cv_results_df)
    output$model_results_train <- renderTable({ train_results_df_formatted })
    output$model_results_test <- renderTable({ test_results_df_formatted })
    output$model_results_cv <- renderTable({ cv_results_df_formatted })
    
    # INTERACTIVE Training Time Plot
    output$timing_plot <- renderPlotly({
      if (nrow(timing_df) == 0) {
        return(plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE)) # No title, no logo
      }
      p <- ggplot(timing_df, aes(x = reorder(Model, Time), y = Time, fill = Model, text = paste("Model:", Model, "<br>Time:", round(Time, 2), "s"))) +
        geom_bar(stat = "identity") +
        labs(x = "Model", y = "Time (seconds)") + # No title
        NULL 
      
      p_themed <- apply_ggplot_theme(p, plot_settings$timing)
      
      ggplotly(p_themed, tooltip = "text") %>%
        layout(
          xaxis = list(title = list(font = list(size = plot_settings$timing$axis_title_size)),
                       tickangle = 45), # Ensure labels are readable
          yaxis = list(title = list(font = list(size = plot_settings$timing$axis_title_size))),
          font = list(family = plot_settings$timing$font_family)
        ) %>%
        config(displaylogo = FALSE) # Remove Plotly logo
    })
    
    
    # INTERACTIVE Actual vs Predicted Plot
    output$scatter_plot <- renderPlotly({
      req(test_predictions_reactive(), test_data_reactive(), input$target_var)
      test_data_actual <- test_data_reactive()[[input$target_var]]
      pred_all_test <- test_predictions_reactive()
      
      # Ensure input$selected_models_ap is not NULL and is reactive.
      # If no models are selected (or none available yet), return an empty plot.
      selected_models <- if (is.null(input$selected_models_ap)) {
        names(pred_all_test) 
      } else {
        input$selected_models_ap
      }
      
      # Filter `pred_all_test` based on `selected_models`
      filtered_pred_all_test <- pred_all_test[names(pred_all_test) %in% selected_models]
      
      plot_data_list <- list()
      for (model_name in names(filtered_pred_all_test)) { 
        if (!is.null(filtered_pred_all_test[[model_name]]) && length(filtered_pred_all_test[[model_name]]) == length(test_data_actual)) {
          df_temp <- data.frame(
            Actual = test_data_actual,
            Predicted = filtered_pred_all_test[[model_name]],
            Model = model_name
          )
          df_temp <- df_temp[complete.cases(df_temp), ]
          if (nrow(df_temp) > 0) {
            plot_data_list[[model_name]] <- df_temp
          }
        }
      }
      
      if (length(plot_data_list) == 0) {
        return(plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE)) # No title, no logo
      }
      
      plot_data_df_scatter <- bind_rows(plot_data_list)
      
      p <- ggplot(plot_data_df_scatter, aes(x = Actual, y = Predicted, color = Model,
                                            text = paste("Model:", Model, "<br>Actual:", Actual, "<br>Predicted:", Predicted))) +
        geom_point(alpha = plot_settings$scatter$point_alpha) +
        geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = plot_settings$scatter$line_color) +
        facet_wrap(~ Model, scales = "free", ncol = 3) +
        labs(x = paste("Actual", target),
             y = paste("Predicted", target)) + 
        theme(legend.position = "none") # plotly creates its own legend
      
      p_themed <- apply_ggplot_theme(p, plot_settings$scatter)
      
      ggplotly(p_themed, tooltip = "text") %>%
        layout(
          xaxis = list(title = list(font = list(size = plot_settings$scatter$axis_title_size))),
          yaxis = list(title = list(font = list(size = plot_settings$scatter$axis_title_size))),
          font = list(family = plot_settings$scatter$font_family)
        ) %>%
        config(displaylogo = FALSE) # Remove Plotly logo
    })
    
    
    # INTERACTIVE Predicted vs Residuals Plot
    output$residual_plot <- renderPlotly({
      req(test_predictions_reactive(), test_data_reactive(), input$target_var)
      test_data_actual <- test_data_reactive()[[input$target_var]]
      pred_all_test <- test_predictions_reactive()
      
      selected_models <- if (is.null(input$selected_models_pr)) {
        names(pred_all_test) 
      } else {
        input$selected_models_pr
      }
      
      filtered_pred_all_test <- pred_all_test[names(pred_all_test) %in% selected_models]
      
      plot_data_list <- list()
      for (model_name in names(filtered_pred_all_test)) { 
        if (!is.null(filtered_pred_all_test[[model_name]]) && length(filtered_pred_all_test[[model_name]]) == length(test_data_actual)) {
          df_temp <- data.frame(
            Predicted = filtered_pred_all_test[[model_name]],
            Residuals = test_data_actual - filtered_pred_all_test[[model_name]],
            Model = model_name
          )
          df_temp <- df_temp[complete.cases(df_temp), ]
          if (nrow(df_temp) > 0) {
            plot_data_list[[model_name]] <- df_temp
          }
        }
      }
      
      if (length(plot_data_list) == 0) {
        return(plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE)) # No title, no logo
      }
      
      plot_data_df_residual <- bind_rows(plot_data_list)
      
      p <- ggplot(plot_data_df_residual, aes(x = Predicted, y = Residuals, color = Model,
                                             text = paste("Model:", Model, "<br>Predicted:", Predicted, "<br>Residual:", Residuals))) +
        geom_point(alpha = plot_settings$residual$point_alpha) +
        geom_hline(yintercept = 0, linetype = "dashed", color = plot_settings$residual$line_color) +
        facet_wrap(~ Model, scales = "free", ncol = 3) +
        labs(x = paste("Predicted", target),
             y = "Residuals") + 
        theme(legend.position = "none") 
      
      p_themed <- apply_ggplot_theme(p, plot_settings$residual)
      
      ggplotly(p_themed, tooltip = "text") %>%
        layout(
          xaxis = list(title = list(font = list(size = plot_settings$residual$axis_title_size))),
          yaxis = list(title = list(font = list(size = plot_settings$residual$axis_title_size))),
          font = list(family = plot_settings$residual$font_family)
        ) %>%
        config(displaylogo = FALSE) # Remove Plotly logo
    })
    
    
    # INTERACTIVE Comparative Plot
    output$comparison_plot <- renderPlotly({
      req(comparison_data())
      df <- comparison_data()
      
      selected_models_comp <- if (is.null(input$selected_models_comp)) {
        unique(df$Model_Type) 
      } else {
        input$selected_models_comp
      }
      
      df_filtered <- df %>%
        filter(Model_Type %in% selected_models_comp) 
      
      if (is.null(df_filtered) || nrow(df_filtered) == 0) {
        return(plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE)) # No title, no logo
      }
      
      df_filtered <- na.omit(df_filtered)
      
      if (nrow(df_filtered) == 0) {
        return(plotly_empty() %>% layout(title = "") %>% config(displaylogo = FALSE)) # No title, no logo
      }
      
      ylim_range <- range(c(df_filtered$Actual, df_filtered$Predicted), na.rm = TRUE)
      
      p <- ggplot(df_filtered, aes(x = Actual, y = Predicted, color = Model_Type,
                                   text = paste("Model:", Model_Type, "<br>Actual:", Actual, "<br>Predicted:", Predicted))) +
        geom_point(alpha = plot_settings$comparison$point_alpha) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = plot_settings$comparison$line_color) +
        labs(x = paste("Actual", input$target_var),
             y = paste("Predicted", input$target_var)) + 
        theme(legend.position = "bottom",
              legend.title = element_blank()) +
        NULL + 
        ylim(ylim_range) +
        scale_x_continuous(labels = scales::scientific_format(digits = 3)) +
        scale_y_continuous(labels = scales::scientific_format(digits = 3))
      
      p_themed <- apply_ggplot_theme(p, plot_settings$comparison)
      
      ggplotly(p_themed, tooltip = "text") %>%
        layout(
          xaxis = list(title = list(font = list(size = plot_settings$comparison$axis_title_size))),
          yaxis = list(title = list(font = list(size = plot_settings$comparison$axis_title_size))),
          font = list(family = plot_settings$comparison$font_family)
        ) %>%
        config(displaylogo = FALSE) # Remove Plotly logo
    })
    
    
    # Comparative Table
    output$comparison_table <- renderTable({
      req(comparison_data())
      df <- comparison_data() %>%
        filter(Model_Type %in% input$selected_models_comp) 
      
      if (is.null(df) || nrow(df) == 0) return(NULL)
      
      df_clean <- na.omit(df)
      
      if (nrow(df_clean) == 0) return(NULL)
      
      df_clean %>%
        group_by(Model_Type) %>%
        summarise(
          MAE = mean(abs(Actual - Predicted), na.rm = TRUE),
          Rsquared = caret::R2(Predicted, Actual),
          Correlation = cor(Predicted, Actual, use = "pairwise.complete.obs")
        ) %>%
        mutate(
          MAE = sprintf("%.6f", MAE),
          Rsquared = sprintf("%.4f", Rsquared),
          Correlation = sprintf("%.4f", Correlation)
        )
    })
    
    # EXPLAINABLE MODELS ----

    # LM Mathematical Model Output
    output$lm_equation_output <- renderUI({
      current_fits <- fits()
      if ("lm" %in% input$models && !is.null(current_fits[["lm"]])) {
        lm_model <- current_fits[["lm"]]$finalModel
        final_features <- features_used_for_modeling()
        req(final_features)
        
        if (inherits(lm_model, "lm")) {
          coefs <- coef(lm_model)
          intercept <- coefs["(Intercept)"]
          feature_coefs <- coefs[names(coefs) %in% final_features]
          
          equation_parts <- c()
          
          if (!is.na(intercept) && is.finite(intercept) && intercept != 0) {
            intercept_formatted_val <- sprintf("%.4e", intercept)
            equation_parts <- c(equation_parts, intercept_formatted_val)
          }
          
          for (feature_name in names(feature_coefs)) {
            coef_val <- feature_coefs[feature_name]
            if (!is.na(coef_val) && is.finite(coef_val) && coef_val != 0) {
              coef_formatted_val <- sprintf("%.4e", abs(coef_val))
              sign_char <- if (coef_val > 0) "+" else "-"
              leading_space <- if (length(equation_parts) > 0) " " else ""
              term_string <- paste0(leading_space, sign_char, coef_formatted_val, " ", feature_name)
              equation_parts <- c(equation_parts, term_string)
            }
          }
          
          plain_equation_string <- if (length(equation_parts) > 0) {
            combined_terms <- paste(equation_parts, collapse = "")
            if (grepl("^\\+", combined_terms)) {
              combined_terms <- sub("^\\+", "", combined_terms)
            }
            combined_terms
          } else {
            "0"
          }
          
          full_plain_equation <- paste0(input$target_var, " = ", plain_equation_string)
          
          div(
            h4("Linear Regression Model Equation (Plain Text / Scientific Notation):"),
            HTML(paste0("<p><code>", full_plain_equation, "</code></p>"))
          ) %>% withSpinner()
          
        } else {
          p("Linear Regression model was selected but the fitted object is not a standard 'lm' model.") %>% withSpinner()
        }
      } else {
        HTML("")
      }
    })
    
    # LM Coefficients Plot (Still ggplot as it's not requested to be interactive yet)
    output$lm_coef_plot <- renderPlot({
      current_fits <- fits()
      if ("lm" %in% input$models && !is.null(current_fits[["lm"]])) {
        lm_model <- current_fits[["lm"]]$finalModel
        final_features <- features_used_for_modeling()
        req(final_features)
        
        if (inherits(lm_model, "lm")) {
          coefs <- coef(lm_model)
          coefs_df <- data.frame(Feature = names(coefs), Coefficient = coefs) %>%
            filter(Feature %in% final_features, !is.na(Coefficient))
          
          validate(need(nrow(coefs_df) > 0, "No valid coefficients to plot for Linear Regression (only intercept or all NA)."))
          
          p <- ggplot(coefs_df, aes(x = reorder(Feature, Coefficient), y = Coefficient, fill = Coefficient > 0)) +
            geom_bar(stat = "identity") +
            coord_flip() +
            labs(x = "Feature", y = "Coefficient Value") + 
            scale_y_continuous(labels = scales::scientific_format(digits = 3))
          apply_ggplot_theme(p, plot_settings$lm_coef)
        } else {
          plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="LM model selected but not a standard 'lm' object")
        }
      } else {
        plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="LM Coefficient Plot (LM model not selected or trained)")
      }
    })
    
    # rpart Decision Tree Plot (Still static as it's complex to make interactive without losing detail)
    output$rpart_tree_plot <- renderPlot({
      current_fits <- fits()
      if ("rpart" %in% input$models && !is.null(current_fits[["rpart"]])) {
        req(rpart.plot)
        rpart_model <- current_fits[["rpart"]]$finalModel
        final_features <- features_used_for_modeling()
        req(final_features)
        
        if (inherits(rpart_model, "rpart")) {
          if (nrow(rpart_model$frame) > 1) {
            prp(rpart_model,
                type = 2,
                extra = 101,
                fallen.leaves = TRUE,
                tweak = plot_settings$rpart_tree$tweak,
                box.palette = plot_settings$rpart_tree$box_palette,
                split.cex = plot_settings$rpart_tree$split_cex
            )
          } else {
            df_clean_for_mean <- df_clean_reactive()
            req(df_clean_for_mean, input$target_var)
            
            if (!is.numeric(df_clean_for_mean[[input$target_var]])) {
              mean_val <- "N/A (Target not numeric)"
            } else if (nrow(df_clean_for_mean) == 0) {
              mean_val <- "N/A (No data)"
            } else {
              mean_val <- round(mean(df_clean_for_mean[[input$target_var]], na.rm = TRUE), 4)
            }
            
            plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="", 
                 xlab="", ylab="")
            text(0.5, 0.6, "Decision Tree model trained,",
                 col = "darkred", cex = 1.2, pos = 4)
            text(0.5, 0.5, "but resulted in a single node (no splits).",
                 col = "darkred", cex = 1.2, pos = 4)
            text(0.5, 0.4, paste("Predicted value is the mean of the training data:", mean_val),
                 col = "darkred", cex = 1.0, pos = 4)
          }
          
        } else {
          plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Decision Tree model selected but not a standard 'rpart' object")
        }
      } else {
        plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="Decision Tree Plot (rpart model not selected or trained)")
      }
    })
    
    # UI for Plot Customization controls (these apply to the underlying ggplot, plotly will interpret them)
    output$hist_plot_controls <- renderUI({
      list(
        h5("Histogram Plot Settings"),
        sliderInput("hist_title_size", "Title Size", min = 8, max = 24, value = plot_settings$hist$title_size),
        sliderInput("hist_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$hist$axis_title_size),
        sliderInput("hist_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$hist$axis_text_size),
        sliderInput("hist_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$hist$legend_text_size),
        selectInput("hist_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$hist$font_family),
        colourInput("hist_fill_color", "Bar Fill Color", value = plot_settings$hist$fill_color),
        sliderInput("hist_bins", "Number of Bins", min = 10, max = 50, value = plot_settings$hist$bins),
        sliderInput("hist_alpha", "Transparency (Alpha)", min = 0.1, max = 1, value = plot_settings$hist$alpha, step = 0.1),
        colourInput("hist_background_color", "Background Color", value = plot_settings$hist$background_color)
      )
    })
    
    output$box_plot_controls <- renderUI({
      list(
        h5("Boxplot Settings"),
        sliderInput("box_title_size", "Title Size", min = 8, max = 24, value = plot_settings$box$title_size),
        sliderInput("box_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$box$axis_title_size),
        sliderInput("box_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$box$axis_text_size),
        sliderInput("box_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$box$legend_text_size),
        selectInput("box_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$box$font_family),
        colourInput("box_fill_color", "Box Fill Color", value = plot_settings$box$fill_color),
        sliderInput("box_alpha", "Transparency (Alpha)", min = 0.1, max = 1, value = plot_settings$box$alpha, step = 0.1),
        colourInput("box_background_color", "Background Color", value = plot_settings$box$background_color)
      )
    })
    
    output$cor_plot_controls <- renderUI({
      list(
        h5("Correlation Plot Settings (Plotly uses ggplot settings)"),
        sliderInput("cor_tl_cex", "Axis Label Size (Approx)", min = 0.5, max = 2.0, value = plot_settings$cor$tl_cex, step = 0.1),
        sliderInput("cor_cl_cex", "Color Bar Label Size (Approx)", min = 0.5, max = 2.0, value = plot_settings$cor$cl_cex, step = 0.1),
        sliderInput("cor_number_cex", "Coefficient Text Size", min = 0.5, max = 2.0, value = plot_settings$cor$number_cex, step = 0.1)
      )
    })
    
    output$boruta_plot_controls <- renderUI({
      list(
        h5("Boruta Plot Settings"),
        sliderInput("boruta_title_size", "Title Size", min = 8, max = 24, value = plot_settings$boruta$title_size), # Still included for consistency, though title is removed.
        sliderInput("boruta_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$boruta$axis_title_size),
        sliderInput("boruta_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$boruta$axis_text_size),
        sliderInput("boruta_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$boruta$legend_text_size),
        selectInput("boruta_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$boruta$font_family),
        colourInput("boruta_background_color", "Background Color", value = plot_settings$boruta$background_color)
      )
    })
    
    output$timing_plot_controls <- renderUI({
      list(
        h5("Training Time Plot Settings"),
        sliderInput("timing_title_size", "Title Size", min = 8, max = 24, value = plot_settings$timing$title_size), # Still included for consistency
        sliderInput("timing_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$timing$axis_title_size),
        sliderInput("timing_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$timing$axis_text_size),
        sliderInput("timing_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$timing$legend_text_size),
        selectInput("timing_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$timing$font_family),
        colourInput("timing_bar_fill_color", "Bar Fill Color", value = plot_settings$timing$bar_fill_color),
        sliderInput("timing_text_label_size", "Text Label Size", min = 2, max = 8, value = plot_settings$timing$text_label_size),
        colourInput("timing_background_color", "Background Color", value = plot_settings$timing$background_color)
      )
    })
    
    output$scatter_plot_controls <- renderUI({
      list(
        h5("Actual vs Predicted Plot Settings"),
        sliderInput("scatter_title_size", "Title Size", min = 8, max = 24, value = plot_settings$scatter$title_size), # Still included for consistency
        sliderInput("scatter_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$scatter$axis_title_size),
        sliderInput("scatter_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$scatter$axis_text_size),
        sliderInput("scatter_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$scatter$legend_text_size),
        selectInput("scatter_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$scatter$font_family),
        sliderInput("scatter_point_alpha", "Point Transparency (Alpha)", min = 0.1, max = 1, value = plot_settings$scatter$point_alpha, step = 0.1),
        colourInput("scatter_line_color", "Reference Line Color", value = plot_settings$scatter$line_color),
        colourInput("scatter_background_color", "Background Color", value = plot_settings$scatter$background_color)
      )
    })
    
    output$residual_plot_controls <- renderUI({
      list(
        h5("Predicted vs Residual Plot Settings"),
        sliderInput("residual_title_size", "Title Size", min = 8, max = 24, value = plot_settings$residual$title_size), # Still included for consistency
        sliderInput("residual_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$residual$axis_title_size),
        sliderInput("residual_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$residual$axis_text_size),
        sliderInput("residual_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$residual$legend_text_size),
        selectInput("residual_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$residual$font_family),
        sliderInput("residual_point_alpha", "Point Transparency (Alpha)", min = 0.1, max = 1, value = plot_settings$residual$point_alpha, step = 0.1),
        colourInput("residual_line_color", "Reference Line Color", value = plot_settings$residual$line_color),
        colourInput("residual_background_color", "Background Color", value = plot_settings$residual$background_color)
      )
    })
    
    output$lm_coef_plot_controls <- renderUI({
      list(
        h5("LM Coefficient Plot Settings"),
        sliderInput("lm_coef_title_size", "Title Size", min = 8, max = 24, value = plot_settings$lm_coef$title_size), # Still included for consistency
        sliderInput("lm_coef_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$lm_coef$axis_title_size),
        sliderInput("lm_coef_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$lm_coef$axis_text_size),
        sliderInput("lm_coef_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$lm_coef$legend_text_size),
        selectInput("lm_coef_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$lm_coef$font_family),
        colourInput("lm_coef_background_color", "Background Color", value = plot_settings$lm_coef$background_color)
      )
    })
    
    output$rpart_tree_plot_controls <- renderUI({
      list(
        h5("Decision Tree Plot Settings"),
        sliderInput("rpart_tweak", "Tweak (Node Size)", min = 0.5, max = 2.0, value = plot_settings$rpart_tree$tweak, step = 0.1),
        selectInput("rpart_box_palette", "Box Color Palette",
                    choices = c("RdBu", "Greens", "Blues", "Reds", "Set1", "Set2", "Set3"),
                    selected = plot_settings$rpart_tree$box_palette),
        sliderInput("rpart_split_cex", "Split Text Size", min = 0.8, max = 2.0, value = plot_settings$rpart_tree$split_cex, step = 0.1)
      )
    })
    
    output$comparison_plot_controls <- renderUI({
      list(
        h5("Comparison Plot Settings"),
        sliderInput("comparison_title_size", "Title Size", min = 8, max = 24, value = plot_settings$comparison$title_size), # Still included for consistency
        sliderInput("comparison_axis_title_size", "Axis Title Size", min = 8, max = 20, value = plot_settings$comparison$axis_title_size),
        sliderInput("comparison_axis_text_size", "Axis Text Size", min = 6, max = 16, value = plot_settings$comparison$axis_text_size),
        sliderInput("comparison_legend_text_size", "Legend Text Size", min = 6, max = 16, value = plot_settings$comparison$legend_text_size),
        selectInput("comparison_font_family", "Font Family", choices = c("sans", "serif", "mono"), selected = plot_settings$comparison$font_family),
        sliderInput("comparison_point_alpha", "Point Transparency (Alpha)", min = 0.1, max = 1, value = plot_settings$comparison$point_alpha, step = 0.1),
        colourInput("comparison_line_color", "Reference Line Color", value = plot_settings$comparison$line_color),
        colourInput("comparison_background_color", "Background Color", value = plot_settings$comparison$background_color)
      )
    })
    
    # Observers for plot settings
    observe({ plot_settings$hist$title_size <- input$hist_title_size %||% plot_settings$hist$title_size })
    observe({ plot_settings$hist$axis_title_size <- input$hist_axis_title_size %||% plot_settings$hist$axis_title_size })
    observe({ plot_settings$hist$axis_text_size <- input$hist_axis_text_size %||% plot_settings$hist$axis_text_size })
    observe({ plot_settings$hist$legend_text_size <- input$hist_legend_text_size %||% plot_settings$hist$legend_text_size })
    observe({ plot_settings$hist$font_family <- input$hist_font_family %||% plot_settings$hist$font_family })
    observe({ plot_settings$hist$fill_color <- input$hist_fill_color %||% plot_settings$hist$fill_color })
    observe({ plot_settings$hist$bins <- input$hist_bins %||% plot_settings$hist$bins })
    observe({ plot_settings$hist$alpha <- input$hist_alpha %||% plot_settings$hist$alpha })
    observe({ plot_settings$hist$background_color <- input$hist_background_color %||% plot_settings$hist$background_color })
    
    observe({ plot_settings$box$title_size <- input$box_title_size %||% plot_settings$box$title_size })
    observe({ plot_settings$box$axis_title_size <- input$box_axis_title_size %||% plot_settings$box$axis_title_size })
    observe({ plot_settings$box$axis_text_size <- input$box_axis_text_size %||% plot_settings$box$axis_text_size })
    observe({ plot_settings$box$legend_text_size <- input$box_legend_text_size %||% plot_settings$box$legend_text_size })
    observe({ plot_settings$box$font_family <- input$box_font_family %||% plot_settings$box$font_family })
    observe({ plot_settings$box$fill_color <- input$box_fill_color %||% plot_settings$box$fill_color })
    observe({ plot_settings$box$alpha <- input$box_alpha %||% plot_settings$box$alpha })
    observe({ plot_settings$box$background_color <- input$box_background_color %||% plot_settings$box$background_color })
    
    # Use a simpler mapping for plotly-based correlations
    observe({ plot_settings$cor$tl_cex <- input$cor_tl_cex %||% plot_settings$cor$tl_cex })
    observe({ plot_settings$cor$cl_cex <- input$cor_cl_cex %||% plot_settings$cor$cl_cex })
    observe({ plot_settings$cor$number_cex <- input$cor_number_cex %||% plot_settings$cor$number_cex }) # This will mainly affect downloads
    
    observe({ plot_settings$boruta$title_size <- input$boruta_title_size %||% plot_settings$boruta$title_size })
    observe({ plot_settings$boruta$axis_title_size <- input$boruta_axis_title_size %||% plot_settings$boruta$axis_title_size })
    observe({ plot_settings$boruta$axis_text_size <- input$boruta_axis_text_size %||% plot_settings$boruta$axis_text_size })
    observe({ plot_settings$boruta$legend_text_size <- input$boruta_legend_text_size %||% plot_settings$boruta$legend_text_size })
    observe({ plot_settings$boruta$font_family <- input$boruta_font_family %||% plot_settings$boruta$font_family })
    observe({ plot_settings$boruta$background_color <- input$boruta_background_color %||% plot_settings$boruta$background_color })
    
    observe({ plot_settings$timing$title_size <- input$timing_title_size %||% plot_settings$timing$title_size })
    observe({ plot_settings$timing$axis_title_size <- input$timing_axis_title_size %||% plot_settings$timing$axis_title_size })
    observe({ plot_settings$timing$axis_text_size <- input$timing_axis_text_size %||% plot_settings$timing$axis_text_size })
    observe({ plot_settings$timing$legend_text_size <- input$timing_legend_text_size %||% plot_settings$timing$legend_text_size })
    observe({ plot_settings$timing$font_family <- input$timing_font_family %||% plot_settings$timing$font_family })
    observe({ plot_settings$timing$bar_fill_color <- input$timing_bar_fill_color %||% plot_settings$timing$bar_fill_color })
    observe({ plot_settings$timing$text_label_size <- input$timing_text_label_size %||% plot_settings$timing$text_label_size })
    observe({ plot_settings$timing$background_color <- input$timing_background_color %||% plot_settings$timing$background_color })
    
    observe({ plot_settings$scatter$title_size <- input$scatter_title_size %||% plot_settings$scatter$title_size })
    observe({ plot_settings$scatter$axis_title_size <- input$scatter_axis_title_size %||% plot_settings$scatter$axis_title_size })
    observe({ plot_settings$scatter$axis_text_size <- input$scatter_axis_text_size %||% plot_settings$scatter$axis_text_size })
    observe({ plot_settings$scatter$legend_text_size <- input$scatter_legend_text_size %||% plot_settings$scatter$legend_text_size })
    observe({ plot_settings$scatter$font_family <- input$scatter_font_family %||% plot_settings$scatter$font_family })
    observe({ plot_settings$scatter$point_alpha <- input$scatter_point_alpha %||% plot_settings$scatter$point_alpha })
    observe({ plot_settings$scatter$line_color <- input$scatter_line_color %||% plot_settings$scatter$line_color })
    observe({ plot_settings$scatter$background_color <- input$scatter_background_color %||% plot_settings$scatter$background_color })
    
    observe({ plot_settings$residual$title_size <- input$residual_title_size %||% plot_settings$residual$title_size })
    observe({ plot_settings$residual$axis_title_size <- input$residual_axis_title_size %||% plot_settings$residual$axis_title_size })
    observe({ plot_settings$residual$axis_text_size <- input$residual_axis_text_size %||% plot_settings$residual$axis_text_size })
    observe({ plot_settings$residual$legend_text_size <- input$residual_legend_text_size %||% plot_settings$residual$legend_text_size })
    observe({ plot_settings$residual$font_family <- input$residual_font_family %||% plot_settings$residual$font_family })
    observe({ plot_settings$residual$point_alpha <- input$residual_point_alpha %||% plot_settings$residual$point_alpha })
    observe({ plot_settings$residual$line_color <- input$residual_line_color %||% plot_settings$residual$line_color })
    observe({ plot_settings$residual$background_color <- input$residual_background_color %||% plot_settings$residual$background_color })
    
    observe({ plot_settings$lm_coef$title_size <- input$lm_coef_title_size %||% plot_settings$lm_coef$title_size })
    observe({ plot_settings$lm_coef$axis_title_size <- input$lm_coef_axis_title_size %||% plot_settings$lm_coef$axis_title_size })
    observe({ plot_settings$lm_coef$axis_text_size <- input$lm_coef_axis_text_size %||% plot_settings$lm_coef$axis_text_size })
    observe({ plot_settings$lm_coef$legend_text_size <- input$lm_coef_legend_text_size %||% plot_settings$lm_coef$legend_text_size })
    observe({ plot_settings$lm_coef$font_family <- input$lm_coef_font_family %||% plot_settings$lm_coef$font_family })
    observe({ plot_settings$lm_coef$background_color <- input$lm_coef_background_color %||% plot_settings$lm_coef$background_color })
    
    observe({ plot_settings$rpart_tree$tweak <- input$rpart_tweak %||% plot_settings$rpart_tree$tweak })
    observe({ plot_settings$rpart_tree$box_palette <- input$rpart_box_palette %||% plot_settings$rpart_tree$box_palette })
    observe({ plot_settings$rpart_tree$split_cex <- input$rpart_split_cex %||% plot_settings$rpart_tree$split_cex })
    
    observe({ plot_settings$comparison$title_size <- input$comparison_title_size %||% plot_settings$comparison$title_size })
    observe({ plot_settings$comparison$axis_title_size <- input$comparison_axis_title_size %||% plot_settings$comparison$axis_title_size })
    observe({ plot_settings$comparison$axis_text_size <- input$comparison_axis_text_size %||% plot_settings$comparison$axis_text_size })
    observe({ plot_settings$comparison$legend_text_size <- input$comparison_legend_text_size %||% plot_settings$comparison$legend_text_size })
    observe({ plot_settings$comparison$font_family <- input$comparison_font_family %||% plot_settings$comparison$font_family })
    observe({ plot_settings$comparison$point_alpha <- input$comparison_point_alpha %||% plot_settings$comparison$point_alpha })
    observe({ plot_settings$comparison$line_color <- input$comparison_line_color %||% plot_settings$comparison$line_color })
    observe({ plot_settings$comparison$background_color <- input$comparison_background_color %||% plot_settings$comparison$background_color })
    
    
    # Download Handlers for Plots
    output$download_hist <- downloadHandler(
      filename = function() { paste("histograms-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(data_raw())
        df <- data_raw()
        num_df <- df %>% select(where(is.numeric))
        validate(need(ncol(num_df) > 0, "No numeric columns available for histogram plots."))
        df_long <- num_df %>% pivot_longer(everything(), names_to = "Feature", values_to = "Value")
        p <- ggplot(df_long, aes(x = Value)) +
          geom_histogram(bins = plot_settings$hist$bins, fill = plot_settings$hist$fill_color, alpha = plot_settings$hist$alpha) +
          facet_wrap(~ Feature, scales = "free") +
          labs(x = "Value", y = "Count") 
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$hist), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    output$download_box <- downloadHandler(
      filename = function() { paste("boxplots-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(data_raw(), input$boxplot_features)
        df <- data_raw()
        selected_features <- input$boxplot_features
        cols_to_plot <- selected_features[selected_features %in% names(df) & sapply(df[selected_features], is.numeric)]
        validate(need(length(cols_to_plot) > 0, "No selected numeric columns available for boxplots after filtering."))
        num_df <- df %>% select(any_of(cols_to_plot))
        df_long <- num_df %>% pivot_longer(everything(), names_to = "Feature", values_to = "Value")
        p <- ggplot(df_long, aes(x = Feature, y = Value)) +
          geom_boxplot(fill = plot_settings$box$fill_color, alpha = plot_settings$box$alpha) +
          labs(x = "Feature", y = "Value") + # No title
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$box), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    output$download_cor <- downloadHandler(
      filename = function() { paste("correlation_matrix-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(data_raw(), input$target_var)
        df <- data_raw()
        target <- input$target_var
        potential_cor_vars <- switch(target,
                                     "dadN" = c("G_max", "R", "Delta_sqrt.G."),
                                     "Total_Energy" = c("N", "a", "F", "d", "C", "R"),
                                     "G_max" = c("a", "F"),
                                     NULL
        )
        cols_needed <- c(target, potential_cor_vars)
        df_subset <- df[, cols_needed, drop = FALSE]
        numeric_subset <- df_subset %>% select(where(is.numeric))
        df_subset_clean <- na.omit(numeric_subset)
        validate(need(ncol(df_subset_clean) >= 2 && nrow(df_subset_clean) > 1, "Not enough data for correlation plot."))
        cor_matrix <- cor(df_subset_clean, use = "pairwise.complete.obs")
        cor_matrix[!is.finite(cor_matrix)] <- NA
        
        # Recreate ggplot for static download
        cor_df <- as.data.frame(cor_matrix)
        cor_df$Var1 <- rownames(cor_df)
        cor_long <- cor_df %>%
          pivot_longer(cols = -Var1, names_to = "Var2", values_to = "Correlation") %>%
          filter(as.integer(factor(Var1, levels = rownames(cor_matrix))) <= as.integer(factor(Var2, levels = colnames(cor_matrix))))
        
        p <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = Correlation)) +
          geom_tile(color = "white") +
          geom_text(aes(label = round(Correlation, 2)), color = "black", size = plot_settings$cor$number_cex * 3) + # Use number_cex for text size
          scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                               midpoint = 0, limit = c(-1,1), space = "Lab",
                               name="Correlation") +
          coord_fixed() +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = plot_settings$cor$tl_cex * 10), # Use tl_cex for labels
                axis.text.y = element_text(size = plot_settings$cor$tl_cex * 10),
                axis.title = element_blank(),
                plot.title = element_blank(), # No title
                legend.position = "bottom",
                legend.text = element_text(size = plot_settings$cor$cl_cex * 10)) # Use cl_cex for color bar labels
        
        ggsave(file, plot = p, device = "png", dpi = 300, width = 10, height = 10)
      }
    )
    
    output$download_boruta <- downloadHandler(
      filename = function() { paste("boruta_plot-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(boruta_results())
        boruta_res <- boruta_results()
        importance_df <- attStats(boruta_res) %>%
          mutate(Feature = rownames(attStats(boruta_res)),
                 Decision = factor(decision, levels = c("Confirmed", "Tentative", "Rejected")))
        p <- ggplot(importance_df, aes(x = reorder(Feature, meanImp), y = meanImp, fill = Decision)) +
          geom_bar(stat = "identity") +
          coord_flip() +
          labs(x = "Feature", y = "Mean Importance") + 
          scale_fill_manual(values = c("Confirmed" = "green", "Tentative" = "orange", "Rejected" = "red"))
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$boruta), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    output$download_timing <- downloadHandler(
      filename = function() { paste("training_time-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(timing_results_reactive())
        timing_df <- timing_results_reactive()
        validate(need(nrow(timing_df) > 0, "No timing data to display."))
        p <- ggplot(timing_df, aes(x = reorder(Model, Time), y = Time, fill = Model)) +
          geom_bar(stat = "identity") +
          geom_text(aes(label = round(Time, 2)), vjust = -0.5, size = plot_settings$timing$text_label_size) +
          labs(x = "Model", y = "Time (seconds)") + # No title
          NULL # Renklerin farklı olması için scale_fill_manual kaldırıldı
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$timing), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    output$download_scatter <- downloadHandler(
      filename = function() { paste("actual_vs_predicted-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(test_predictions_reactive(), test_data_reactive(), input$target_var)
        test_data_actual <- test_data_reactive()[[input$target_var]]
        pred_all_test <- test_predictions_reactive()
        # For download, include all models initially, or add a separate input for downloaded plot models
        selected_models_for_download <- names(pred_all_test)
        
        plot_data_list <- list()
        for (model_name in selected_models_for_download) {
          if (!is.null(pred_all_test[[model_name]]) && length(pred_all_test[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(Actual = test_data_actual, Predicted = pred_all_test[[model_name]], Model = model_name)
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        validate(need(length(plot_data_list) > 0, "No valid predictions to plot."))
        plot_data_df_scatter <- bind_rows(plot_data_list)
        p <- ggplot(plot_data_df_scatter, aes(x = Actual, y = Predicted, color = Model)) +
          geom_point(alpha = plot_settings$scatter$point_alpha) +
          geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = plot_settings$scatter$line_color) +
          facet_wrap(~ Model, scales = "free", ncol = 3) +
          labs(x = paste("Actual", input$target_var),
               y = paste("Predicted", input$target_var)) + # No title
          theme(legend.position = "none") # plotly creates its own legend
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$scatter), device = "png", dpi = 300, width = 12, height = 10)
      }
    )
    
    output$download_residual <- downloadHandler(
      filename = function() { paste("predicted_vs_residual-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(test_predictions_reactive(), test_data_reactive(), input$target_var)
        test_data_actual <- test_data_reactive()[[input$target_var]]
        pred_all_test <- test_predictions_reactive()
        # For download, include all models initially, or add a separate input for downloaded plot models
        selected_models_for_download <- names(pred_all_test)
        
        plot_data_list <- list()
        for (model_name in selected_models_for_download) {
          if (!is.null(pred_all_test[[model_name]]) && length(pred_all_test[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(Predicted = pred_all_test[[model_name]], Residuals = test_data_actual - pred_all_test[[model_name]], Model = model_name)
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        validate(need(length(plot_data_list) > 0, "No valid predictions to plot residuals."))
        plot_data_df_residual <- bind_rows(plot_data_list)
        p <- ggplot(plot_data_df_residual, aes(x = Predicted, y = Residuals, color = Model)) +
          geom_point(alpha = plot_settings$residual$point_alpha) +
          geom_hline(yintercept = 0, linetype = "dashed", color = plot_settings$residual$line_color) +
          facet_wrap(~ Model, scales = "free", ncol = 3) +
          labs(x = paste("Predicted", input$target_var),
               y = "Residuals") + # No title
          theme(legend.position = "none") # plotly creates its own legend
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$residual), device = "png", dpi = 300, width = 12, height = 10)
      }
    )
    
    output$download_lm_coef <- downloadHandler(
      filename = function() { paste("lm_coefficients-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        current_fits <- fits()
        validate(need("lm" %in% input$models && !is.null(current_fits[["lm"]]), "LM model not selected or trained."))
        lm_model <- current_fits[["lm"]]$finalModel
        final_features <- features_used_for_modeling()
        validate(need(inherits(lm_model, "lm"), "LM model is not a standard 'lm' object."))
        coefs <- coef(lm_model)
        coefs_df <- data.frame(Feature = names(coefs), Coefficient = coefs) %>%
          filter(Feature %in% final_features, !is.na(Coefficient))
        validate(need(nrow(coefs_df) > 0, "No valid coefficients to plot for Linear Regression."))
        p <- ggplot(coefs_df, aes(x = reorder(Feature, Coefficient), y = Coefficient, fill = Coefficient > 0)) +
          geom_bar(stat = "identity") +
          coord_flip() +
          labs(x = "Feature", y = "Coefficient Value") + # No title
          scale_y_continuous(labels = scales::scientific_format(digits = 3))
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$lm_coef), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    output$download_rpart_tree <- downloadHandler(
      filename = function() { paste("decision_tree-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        current_fits <- fits()
        validate(need("rpart" %in% input$models && !is.null(current_fits[["rpart"]]), "Decision Tree model not selected or trained."))
        rpart_model <- current_fits[["rpart"]]$finalModel
        validate(need(inherits(rpart_model, "rpart"), "Decision Tree model is not a standard 'rpart' object."))
        
        png(file, width = 12, height = 10, units = "in", res = 300)
        if (nrow(rpart_model$frame) > 1) {
          prp(rpart_model,
              type = 2,
              extra = 101,
              fallen.leaves = TRUE,
              tweak = plot_settings$rpart_tree$tweak,
              box.palette = plot_settings$rpart_tree$box_palette,
              split.cex = plot_settings$rpart_tree$split_cex
              # main argument is for title, not setting it here as requested
          )
        } else {
          plot(NULL, type="n", xlim=c(0,1), ylim=c(0,1), main="", # No title
               xlab="", ylab="")
          text(0.5, 0.5, "Decision Tree model resulted in a single node (no splits).", col = "darkred", cex = 1.2)
        }
        dev.off()
      }
    )
    
    output$download_comparison <- downloadHandler(
      filename = function() { paste("comparison_plot-", Sys.Date(), ".png", sep="") },
      content = function(file) {
        req(comparison_data())
        df <- comparison_data()
        # For download, include all models initially, or add a separate input for downloaded plot models
        selected_models_for_download <- unique(df$Model_Type)
        df <- df %>% filter(Model_Type %in% selected_models_for_download)
        
        validate(need(!is.null(df) && nrow(df) > 0, "No valid comparison data available."))
        df <- na.omit(df)
        validate(need(nrow(df) >= 2, "Not enough valid data points for comparison plot after removing NAs."))
        
        ylim_range <- tryCatch(
          quantile(df$Actual, probs = c(0.01, 0.99), na.rm = TRUE),
          error = function(e) {
            c(min(df$Actual, df$Predicted, na.rm = TRUE),
              max(df$Actual, df$Predicted, na.rm = TRUE))
          }
        )
        p <- ggplot(df, aes(x = Actual, y = Predicted, color = Model_Type)) +
          geom_point(alpha = plot_settings$comparison$point_alpha) +
          geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = plot_settings$comparison$line_color) +
          labs(x = paste("Actual", input$target_var),
               y = paste("Predicted", input$target_var)) + 
          theme(legend.position = "bottom",
                legend.title = element_blank()) +
          NULL + 
          ylim(ylim_range) +
          scale_x_continuous(labels = scales::scientific_format(digits = 3)) +
          scale_y_continuous(labels = scales::scientific_format(digits = 3))
        ggsave(file, plot = apply_ggplot_theme(p, plot_settings$comparison), device = "png", dpi = 300, width = 10, height = 8)
      }
    )
    
    
    # Define reactive values for LM and rpart models for report generation
    lm_coef_df_for_report_reactive <- reactiveVal(NULL)
    rpart_model_for_report_reactive <- reactiveVal(NULL)
    
    # Calculate LM coefs for report
    observeEvent(fits(), {
      current_fits <- fits()
      if ("lm" %in% input$models && !is.null(current_fits[["lm"]])) {
        lm_model_report <- current_fits[["lm"]]$finalModel
        if (inherits(lm_model_report, "lm")) {
          coefs_report <- coef(lm_model_report)
          lm_coef_df_for_report_reactive(
            data.frame(Feature = names(coefs_report), Coefficient = coefs_report) %>%
              filter(Feature %in% features_used_for_modeling(), !is.na(Coefficient))
          )
        } else {
          lm_coef_df_for_report_reactive(NULL)
        }
      } else {
        lm_coef_df_for_report_reactive(NULL)
      }
      
      # Set rpart model for report
      if ("rpart" %in% input$models && !is.null(current_fits[["rpart"]])) {
        rpart_model_for_report_reactive(current_fits[["rpart"]]$finalModel)
      } else {
        rpart_model_for_report_reactive(NULL)
      }
    })
    
    # PDF Report Generation Function
    generate_pdf_report <- function() {
      req(
        data_raw(),
        df_clean_reactive(),
        outlier_summary_reactive(),
        timing_results_reactive(),
        test_predictions_reactive(),
        all_model_results_reactive(),
        boruta_results(),
        comparison_data(),
        test_data_reactive(),
        input$target_var,
        lm_coef_df_for_report_reactive(), 
        rpart_model_for_report_reactive() 
      )
      
      showNotification("Generating PDF report...", type = "message", duration = NULL)
      temp_dir <- tempdir()
      temp_pdf_file <- file.path(temp_dir, "report.pdf")
      
      # Use the external Rmd file directly
      report_rmd_path <- file.path(getwd(), "report_template.Rmd") 
      
      # Make sure the file exists
      if (!file.exists(report_rmd_path)) {
        showNotification("Error: 'report_template.Rmd' not found in the app directory. Please create it.", type = "error")
        return(NULL)
      }
      
      # Correlation matrix calculation
      cor_matrix <- NULL
      if(!is.null(data_raw()) && !is.null(input$target_var)) {
        potential_vars <- switch(input$target_var,
                                 "dadN" = c("G_max", "R", "Delta_sqrt.G."),
                                 "Total_Energy" = c("N", "a", "F", "d", "C", "R"),
                                 "G_max" = c("a", "F"),
                                 NULL)
        
        if (!is.null(potential_vars)) {
          cols_needed <- c(input$target_var, potential_vars)
          if (all(cols_needed %in% names(data_raw()))) {
            df_subset <- data_raw()[, cols_needed, drop = FALSE]
            numeric_subset <- df_subset %>% select(where(is.numeric))
            if (ncol(numeric_subset) > 1) {
              df_subset_clean <- na.omit(numeric_subset)
              if (nrow(df_subset_clean) > 1) {
                cor_matrix <- cor(df_subset_clean, use = "pairwise.complete.obs")
              }
            }
          }
        }
      }
      
      # Scatter plot data
      plot_data_df_scatter <- NULL
      test_predictions <- test_predictions_reactive()
      if (!is.null(test_predictions) && length(test_predictions) > 0) {
        test_data <- test_data_reactive()
        test_data_actual <- test_data[[input$target_var]]
        plot_data_list <- list()
        
        for (model_name in names(test_predictions)) {
          if (!is.null(test_predictions[[model_name]]) && length(test_predictions[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(
              Actual = test_data_actual,
              Predicted = test_predictions[[model_name]],
              Model = model_name
            )
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        
        if (length(plot_data_list) > 0) plot_data_df_scatter <- bind_rows(plot_data_list)
      }
      
      # Residual plot data
      plot_data_df_residual <- NULL
      if (!is.null(test_predictions) && length(test_predictions) > 0) {
        test_data_actual <- test_data[[input$target_var]]
        plot_data_list <- list()
        
        for (model_name in names(test_predictions)) {
          if (!is.null(test_predictions[[model_name]]) && length(test_predictions[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(
              Predicted = test_predictions[[model_name]],
              Residuals = test_data_actual - test_predictions[[model_name]],
              Model = model_name
            )
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        
        if (length(plot_data_list) > 0) plot_data_df_residual <- bind_rows(plot_data_list)
      }
      
      app_data_for_report <- list(
        data_raw = data_raw(),
        df_clean = df_clean_reactive(),
        outlier_summary_text = outlier_summary_reactive(),
        target_var = input$target_var,
        cor_matrix = cor_matrix,
        boruta_results = boruta_results(),
        train_results_df = all_model_results_reactive()$train,
        test_results_df = all_model_results_reactive()$test,
        cv_results_df = all_model_results_reactive()$cv,
        timing_df = timing_results_reactive(),
        plot_data_df_scatter = plot_data_df_scatter,
        plot_data_df_residual = plot_data_df_residual,
        lm_coef_df = lm_coef_df_for_report_reactive(), 
        rpart_model = rpart_model_for_report_reactive(), 
        comparison_data_df = comparison_data(),
        plot_settings = isolate(reactiveValuesToList(plot_settings)), 
        boxplot_features = input$boxplot_features 
      )
      
      tryCatch({
        rmarkdown::render(
          report_rmd_path, # Use the path to the external Rmd file
          output_file = temp_pdf_file,
          params = list(app_data = app_data_for_report),
          envir = new.env(parent = globalenv())
        )
        showNotification("PDF report generated successfully!", type = "message")
        utils::browseURL(temp_pdf_file)
      }, error = function(e) {
        showNotification(paste("Error generating PDF report:", e$message), type = "error")
        message("PDF report generation error: ", e$message)
      })
    }
    
    # HTML Report Generation Function
    generate_html_report <- function() {
      req(
        data_raw(),
        df_clean_reactive(),
        outlier_summary_reactive(),
        timing_results_reactive()
      )
      
      showNotification("Generating HTML report...", type = "message", duration = NULL)
      temp_dir <- tempdir()
      temp_html_file <- file.path(temp_dir, "report.html")
      
      # Use the external Rmd file directly for HTML
      report_rmd_path <- file.path(getwd(), "report_template.Rmd") 
      if (!file.exists(report_rmd_path)) {
        showNotification("Error: 'report_template.Rmd' not found in the app directory. Please create it.", type = "error")
        return(NULL)
      }
      
      # Correlation matrix calculation
      cor_matrix <- NULL
      if(!is.null(data_raw()) && !is.null(input$target_var)) {
        potential_vars <- switch(input$target_var,
                                 "dadN" = c("G_max", "R", "Delta_sqrt.G."),
                                 "Total_Energy" = c("N", "a", "F", "d", "C", "R"),
                                 "G_max" = c("a", "F"),
                                 NULL)
        
        if (!is.null(potential_vars)) {
          cols_needed <- c(input$target_var, potential_vars)
          if (all(cols_needed %in% names(data_raw()))) {
            df_subset <- data_raw()[, cols_needed, drop = FALSE]
            numeric_subset <- df_subset %>% select(where(is.numeric))
            if (ncol(numeric_subset) > 1) {
              df_subset_clean <- na.omit(numeric_subset)
              if (nrow(df_subset_clean) > 1) {
                cor_matrix <- cor(df_subset_clean, use = "pairwise.complete.obs")
              }
            }
          }
        }
      }
      
      # Scatter plot data
      plot_data_df_scatter <- NULL
      test_predictions <- test_predictions_reactive()
      if (!is.null(test_predictions) && length(test_predictions) > 0) {
        test_data <- test_data_reactive()
        test_data_actual <- test_data[[input$target_var]]
        plot_data_list <- list()
        
        for (model_name in names(test_predictions)) {
          if (!is.null(test_predictions[[model_name]]) && length(test_predictions[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(
              Actual = test_data_actual,
              Predicted = test_predictions[[model_name]],
              Model = model_name
            )
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        
        if (length(plot_data_list) > 0) plot_data_df_scatter <- bind_rows(plot_data_list)
      }
      
      # Residual plot data
      plot_data_df_residual <- NULL
      if (!is.null(test_predictions) && length(test_predictions) > 0) {
        test_data_actual <- test_data[[input$target_var]]
        plot_data_list <- list()
        
        for (model_name in names(test_predictions)) {
          if (!is.null(test_predictions[[model_name]]) && length(test_predictions[[model_name]]) == length(test_data_actual)) {
            df_temp <- data.frame(
              Predicted = test_predictions[[model_name]],
              Residuals = test_data_actual - test_predictions[[model_name]],
              Model = model_name
            )
            df_temp <- df_temp[complete.cases(df_temp), ]
            if (nrow(df_temp) > 0) plot_data_list[[model_name]] <- df_temp
          }
        }
        
        if (length(plot_data_list) > 0) plot_data_df_residual <- bind_rows(plot_data_list)
      }
      
      app_data_for_report <- list(
        data_raw = data_raw(),
        df_clean = df_clean_reactive(),
        outlier_summary_text = outlier_summary_reactive(),
        target_var = input$target_var,
        cor_matrix = cor_matrix,
        boruta_results = boruta_results(),
        train_results_df = all_model_results_reactive()$train,
        test_results_df = all_model_results_reactive()$test,
        cv_results_df = all_model_results_reactive()$cv,
        timing_df = timing_results_reactive(),
        plot_data_df_scatter = plot_data_df_scatter,
        plot_data_df_residual = plot_data_df_residual,
        lm_coef_df = lm_coef_df_for_report_reactive(), 
        rpart_model = rpart_model_for_report_reactive(), 
        comparison_data_df = comparison_data(),
        plot_settings = isolate(reactiveValuesToList(plot_settings)), 
        boxplot_features = input$boxplot_features 
      )
      
      tryCatch({
        rmarkdown::render(
          report_rmd_path, 
          output_file = temp_html_file,
          params = list(app_data = app_data_for_report),
          envir = new.env(parent = globalenv())
        )
        showNotification("HTML report generated successfully!", type = "message")
        utils::browseURL(temp_html_file)
      }, error = function(e) {
        showNotification(paste("Error generating HTML report:", e$message), type = "error")
        message("HTML report generation error: ", e$message)
      })
    }
    
    # Report buttons observers
    observeEvent(input$generate_pdf_report, {
      generate_pdf_report()
    })
    
    observeEvent(input$generate_html_report, {
      generate_html_report()
    })
    
    # Download Cleaned Data
    output$download_cleaned_data <- downloadHandler(
      filename = function() {
        paste("cleaned_data-", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(df_clean_reactive())
        write.csv(df_clean_reactive(), file, row.names = FALSE)
      }
    )
    
    # Download All Model Metrics
    output$download_all_metrics <- downloadHandler(
      filename = function() {
        paste("model_metrics-", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(all_model_results_reactive()$train,
            all_model_results_reactive()$test,
            all_model_results_reactive()$cv)
        
        train_df <- all_model_results_reactive()$train %>%
          rename_with(~ paste0(., "_Train"), .cols = -Model)
        
        test_df <- all_model_results_reactive()$test %>%
          rename_with(~ paste0(., "_Test"), .cols = -Model)
        
        cv_df <- all_model_results_reactive()$cv
        
        all_metrics_df <- train_df %>%
          full_join(test_df, by = "Model") %>%
          full_join(cv_df, by = "Model")
        
        write.csv(all_metrics_df, file, row.names = FALSE)
      }
    )
  })
}

shinyApp(ui = ui, server = server)