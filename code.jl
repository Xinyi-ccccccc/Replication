### A Pluto.jl notebook ###
# v0.19.37

using Markdown
using InteractiveUtils

# ╔═╡ b447f900-177a-11ef-1aff-578b4e55dd26
#Add the pkg
begin
using Pkg
Pkg.add(["Gadfly", "Cairo", "Fontconfig", "DataFrames", "CSV", "Statistics"])
Pkg.add("Compose")
end

# ╔═╡ c3c3810a-793e-47e4-b406-5e2f7d3523e0
begin
Pkg.add("GLM")
Pkg.add("StatsModels")
end

# ╔═╡ d1085100-8d15-439c-8593-672a6d9387ee
begin
using DataFrames
using CSV
using Gadfly
using StatsBase
using Cairo
using Fontconfig
using Compose
end

# ╔═╡ 96a37de7-0a96-48c6-b2d8-5a595db843c1
begin
using GLM
using StatsModels
end

# ╔═╡ 60980ed0-cc34-400c-953b-bfa554ceffb9
md"""
## Introduction
This Document is to replicate the Figure 1 and Table 3 for the paper 'Second-Best Fairness: The Trade-off between False Positives and False Negatives' on AER in 2023.

The paper investigates how individuals trade off between false positives (giving undeserving individuals more than they deserve) and false negatives (giving deserving individuals less than they deserve) in distributive decisions. Using a large-scale experiment with 4000 participants, the authors explore people's preferences and social attitudes towards these errors in scenarios where decision-makers have limited information.

## Methodology
The authors conducted an experiment where participants, acting as third-party spectators, decided on the distribution of payments between two groups of workers. The first group had workers who completed an assignment, while the second group included some who falsely reported completing it. Spectators were randomized into five treatments varying by the number of cheaters in the second group. They had to choose either to distribute money equally between the groups, causing false positives, or to give all the money to the first group, causing false negatives. Spectators' choices were analyzed to understand their trade-offs between false positives and false negatives.

## Replication results
I successfully replicated Figure 1 and Table 3 from the paper. Furthermore, I extended this research by proposing to conduct the experiment in a GPT environment. I wrote the code in Julia to call GPT-4 using API keys. However, the experiment can only be replicated in a fully funded environment, so I am only providing the code here.
"""

# ╔═╡ f25beb99-386c-44e5-bb3e-ae621416810a
md"""
Below are the code for our replication.
"""

# ╔═╡ 7ce6af5b-6c00-47ad-848a-e33523f0b619
# Load the dataset (assuming it's in a CSV file named "data.csv")
begin
cd("/Users/xinyicao/Dropbox/rep_pkg/2ndbest_rep_pkg/Data/Processed_Data")
data = CSV.read("analyticaldata.csv", DataFrame)
end

# ╔═╡ d56757ab-9e76-4c57-a473-bccf04941d67
function convert_treatment_column(column)
    clean_column = replace.(column, "Treatment " => "")
    return parse.(Int, clean_column)
end

# ╔═╡ 034b73c8-3f0b-46ca-b5bd-9a81677815f1
data.h_treatment = convert_treatment_column(data.h_treatment)

# ╔═╡ 1045af43-8200-411a-899f-46c646dfa5f2
semean(x) = std(x) / sqrt(length(x))

# ╔═╡ 45596aac-1245-424e-9538-7f0f5257f87b
# Function to process data and generate plot
function process_and_plot(data::DataFrame, drop_cond::AbstractVector{Bool}, probability_col::Symbol, pay_col::Symbol, title_str::String, filename::String)
    # Drop rows based on condition
    filtered_data = data[.!drop_cond, :]
    
    # Collapse data by calculating mean and standard error of pay
    grouped_data = combine(groupby(filtered_data, probability_col), pay_col => mean => :pay, pay_col => semean => :se_pay)

    # Generate hi and lo columns
    grouped_data.hi = grouped_data.pay .+ grouped_data.se_pay
    grouped_data.lo = grouped_data.pay .- grouped_data.se_pay

    # Create the plot
    p = plot(grouped_data,
        x=probability_col, y=:pay,
        ymin=:lo, ymax=:hi,
        Geom.bar(position=:dodge),
        Geom.errorbar,
        Scale.x_discrete(levels=[0.0, 0.25, 0.5, 0.75, 1.0]),
        Scale.y_continuous(minvalue=0, maxvalue=1),
        Guide.xlabel("Probability of false claim"),
        Guide.ylabel("Share paying ± s.e.m."),
        Guide.title(title_str),
        Theme(bar_spacing=0mm, stroke_color=c->"black")
    )
    
    
    return p
end


# ╔═╡ 1b429bc9-92ce-4d29-bff8-5861eef80958
begin
# Define drop conditions
drop_condition_all_comp = data.h_treatment .> 5
drop_condition_all_earn = data.replication .== 0
drop_condition_usa_comp = (data.h_treatment .> 5) .| (data.Norway .== 1)
drop_condition_usa_earn = (data.replication .== 0) .| (data.Norway .== 1)
drop_condition_norway_comp = (data.h_treatment .> 5) .| (data.Norway .== 0)
drop_condition_norway_earn = (data.replication .== 0) .| (data.Norway .== 0)
end


# ╔═╡ 2b5c0f1e-816e-4a62-bbd6-f94a0b5dae5d
begin
# Process data and generate plots
p1= process_and_plot(data, drop_condition_all_comp, :probability, :pay, "All - Compensation", "figure1_a.pdf")
p2= process_and_plot(data, drop_condition_all_earn, :probability, :pay, "All - Earnings", "figure1_b.pdf")
p3= process_and_plot(data, drop_condition_usa_comp, :probability, :pay, "USA - Compensation", "figure1_c.pdf")
p4=process_and_plot(data, drop_condition_usa_earn, :probability, :pay, "USA - Earnings", "figure1_d.pdf")
p5=process_and_plot(data, drop_condition_norway_comp, :probability, :pay, "Norway - Compensation", "figure1_e.pdf")
p6=process_and_plot(data, drop_condition_norway_earn, :probability, :pay, "Norway - Earnings", "figure1_f.pdf")
end

# ╔═╡ 71e65680-5eef-4b66-b518-8365e5314a91
hstack_all = hstack(p1, p2)

# ╔═╡ 3115daec-7897-47ac-b72d-6d532e741224
hstack_us = hstack(p3, p4)

# ╔═╡ c1fcd87f-0d92-4fb9-a815-c103cf77611a
hstack_nor = hstack(p5, p6)

# ╔═╡ 618c35f7-dac0-4148-bf65-adfe85c4a8e1
md"""
Figure 1 illustrates how spectators choose to pay in two experimental contexts: the Compensation experiment and the Earnings experiment. These choices are analyzed for pooled samples, as well as samples specifically from the United States and Norway. The treatments are defined by the probability that a worker has filed a false claim, with standard error lines included for precision.

In the Compensation experiment, displayed in the left panels, the overall trend for the pooled sample shows a decrease in the proportion of spectators opting to pay as the likelihood of a false claim increases. This pattern is also observed when examining the United States and Norway separately. However, there are distinct differences between the two countries. Spectators in the United States are more likely to pay despite a high probability of false claims compared to their Norwegian counterparts.

The right panels present data from the Earnings experiment. For the pooled sample, when it is certain that the worker has completed the assignment, a substantial majority of 92.8 percent of spectators choose to pay. Conversely, when it is certain that the worker has filed a false claim, 90.3 percent of spectators choose not to pay. As the probability of a false claim rises, the willingness to pay diminishes, with notable declines occurring as the probability shifts from 0.5 to 0.75 and from 0.75 to 1.

The behaviors observed in the United States and Norway within the Earnings experiment reflect similar trends to the pooled data. However, American spectators show a higher propensity to pay even with high probabilities of false claims. In Norway, the decrease in the willingness to pay is more gradual up to a probability of 0.75, after which there is a steeper decline compared to the United States.

Overall, the figure demonstrates consistent patterns in fairness preferences across both experiments and highlights differences in spectators' leniency and strictness between the United States and Norway.
"""

# ╔═╡ a86ba704-91ba-428d-919e-052ff114198f
begin
# Define the control variables
controls = [:male, :lowage, :lowincome, :loweducation, :rightwing]
# Define the treatment variables
treatments = [:prob25, :prob50, :prob75, :prob100]
end

# ╔═╡ 108d1e00-6754-4d6e-aa63-0e5bb3588ac9


function perform_regressions(data, subset_condition)
    filtered_data = data[subset_condition .& .!ismissing.(data.sca_weight) .& .!ismissing.(data.pay), :]
    
    if nrow(filtered_data) == 0
        error("The subset data is empty after applying the conditions.")
    end
    
    models = []
    weights =  collect(skipmissing(filtered_data.sca_weight)) 
    push!(models, lm(@formula(pay ~ prob25 + prob50 + prob75 + prob100), filtered_data, wts = weights))
    push!(models, lm(@formula(pay ~ prob25 + prob50 + prob75 + prob100 + male + lowage + lowincome + loweducation + rightwing), filtered_data, wts = weights))
    return models
end

# ╔═╡ a939bc07-1b32-4ca0-83f1-159613ed6ebf
# Perform regressions for ALL
all_models = perform_regressions(data, data.h_treatment .< 6)

# ╔═╡ aee4bcb5-2e8d-4321-a9ee-1c1164b2e5ff
us_models_1 = perform_regressions(data, data.Norway .== 1 .& data.h_treatment .< 6)

# ╔═╡ fe005670-b7a1-4cba-8614-16d5d1569b8e
norway_model = perform_regressions(data, data.Norway .== 0 .& data.h_treatment .< 6)

# ╔═╡ 74a16a95-fcbc-4616-9368-ebd52cca9540
function present_results(models)
    for (i, model) in enumerate(models)
        println("Model $i:")
        println("Coefficients:")
        coef_table = coeftable(model)
        println(coef_table)
        
        println("R-squared: ", r2(model))
        
        println("---------------------------------------------------")
    end
end

# ╔═╡ e62dd877-9705-413a-982b-515c0335e5d0
begin
println("All Models:")
present_results(all_models)
end

# ╔═╡ bbb3ddd4-97dc-4646-a4be-0e8ff3372261
begin
println("US Models:")
present_results(us_models_1)
end

# ╔═╡ 3f5a148a-831d-400f-9e6a-19324e6c31f2
begin
println("Norway Model:")
present_results(norway_model)
end

# ╔═╡ d9baada1-5e99-400f-9356-2e0e3cd9b538
md"""
Table 3 details the results of an OLS regression analysis on the effect of different probabilities of false claims on spectators' decisions to pay compensation in the Compensation experiment. This analysis includes pooled data and separate samples from the United States and Norway, with controls for income, education, gender, age, and political ideology, and population-weighted estimates.

For the pooled sample, introducing a 0.25 probability that a worker has filed a false claim leads to a 10.4 percentage point decrease in the likelihood that spectators choose to pay the compensation, with a p-value of less than 0.001. When the probability of a false claim is 0.5, the share of spectators paying the compensation drops by 17.6 percentage points, indicating that 72.4 percent of spectators still choose to pay despite the equal likelihood of a false claim. This suggests a significant preference for avoiding false negatives (not paying when the claim is legitimate) over false positives (paying when the claim is fraudulent), with a notable difference of 44.8 percentage points, supported by a p-value of less than 0.001.

As the probability of a false claim increases to 0.75, the likelihood of spectators paying compensation decreases substantially by 46.5 percentage points, and when the probability reaches 1 (certainty of a false claim), the share paying drops dramatically by 79.7 percentage points, both with p-values less than 0.001. These findings suggest that as the likelihood of deception increases, spectators become significantly less willing to pay compensation.

Including control variables for income, education, gender, age, and political ideology does not significantly alter these treatment effects, indicating the robustness of the results.

In both the United States and Norway, the treatment effects remain highly significant. When the probability of a false claim is 0.5, a large majority of spectators in both countries still choose to pay the compensation. The difference between the share of false negative averse and false positive averse spectators is 41.6 percentage points in the United States and 48.1 percentage points in Norway, both with p-values less than 0.001. These results indicate that spectators in both countries prefer to avoid false negatives significantly more than false positives, reflecting similar fairness preferences in both cultural contexts.
"""

# ╔═╡ 0f672d40-1960-49f7-92e5-5bd901ba2d26

md"""
##### Extension: experiment on GPT. It's better to run it in VScode, so I disabled the cells just for pasting the code here.
"""

# ╔═╡ 9f43cb68-4fc6-4145-8804-5196cc7fd705
# ╠═╡ disabled = true
#=╠═╡
# -------------------------------------------------------------
# All functions for prompting, extracting responses, etc.
# -------------------------------------------------------------
sleep_time = 0;

function query(prompt, N)
    rvec = [];
    if N <=128
        rvec = create_completion(api_key, "text-davinci-003";
            prompt= prompt,
            temperature=1,
            max_tokens=100,
            top_p=1.0,
            n = N,
            frequency_penalty=0.0,
            presence_penalty=0.0,
            stop=["\"\"\""])
    else
        nqueries = floor(N/128)+1;
        if floor(N/128) == N/128
            nqueries = floor(N/128);
        end
        for i = 1:nqueries
            if N > (i-1)*128
                println("Waiting before/between queries.......")
                sleep(sleep_time)
                n_for_request = 128;
                if (i==nqueries) & (N > (i-1)*128)
                    n_for_request = Int(N - (i-1)*128);
                end
                rtemp = create_completion(api_key, "text-davinci-003";
                    prompt= prompt,
                    temperature=1,
                    max_tokens=30,
                    top_p=1.0,
                    n=n_for_request,
                    frequency_penalty=0.0,
                    presence_penalty=0.0,
                    stop=["\"\"\""])
                println("Query $(i)/$(nqueries) Done")
                push!(rvec, rtemp)
            end
        end
    end
    return rvec
end

function get_choices(response_vec)
    choices = [];
    if typeof(response_vec) <: OpenAIResponse
        nresponses = length(response_vec.response.choices);
        for i = 1:nresponses
            push!(choices, getindex(response_vec.response.choices,i)[:text]);
        end
    else
        for outer_i = 1:length(response_vec)
            nresponses = length(response_vec[outer_i].response.choices);
            for i = 1:nresponses
                push!(choices, getindex(response_vec[outer_i].response.choices,i)[:text]);
            end
        end
    end
    return choices
end

function make_prompt_compensation_claim()
    prompt = """A few days ago, we recruited people via an international online labor market. It was randomly decided who were offered income-generating work and who were not offered work. Those who were not offered work were entitled to 4 USD as partial compensation for their loss of income from not being offered work. Those who were offered work could file a false claim for compensation by wrongly stating that they had not been offered work. We told them that a third party would decide whether a claim for compensation is to be paid out.

Your task will now be to decide whether a person’s claim for compensation is to be paid out. It is certain (100 percent probability) that this person has filed a correct claim for compensation.

Do you approve the payment of the compensation?

Decision: """
    return prompt
end

# Import packages
# Install all first using "] add ..."
using CSV, JSON
using OpenAI, DataFrames

sleep_time = 5;
length_per_iter = 50;

# Include api_key provided by OpenAI service
api_key = "";

# File with functions needs to be in the same path
include("SAMPLE_prompting_functions.jl");

# Define path for results
study_1 = "./results_study1";
  ╠═╡ =#

# ╔═╡ 3a859274-ec5a-4c71-93a9-c0e5f242680a
# ╠═╡ disabled = true
#=╠═╡
# ------------------------------------------------------------------
# ------------------------------------------------------------------
# Experiment 1: Compensation Claim Decision
# ------------------------------------------------------------------
# ------------------------------------------------------------------

response_vec = [];
N = 150;  # Number of queries

cd(study_1);

# Create and execute the compensation claim prompt
compensation_prompt = make_prompt_compensation_claim();
responses = query(compensation_prompt, N);
choices = get_choices(responses);

# Save the results to a CSV file
df = DataFrame(choice=choices);
CSV.write("compensation_claims.csv", df, append=true);

println("Compensation claims saved.");

  ╠═╡ =#

# ╔═╡ Cell order:
# ╟─60980ed0-cc34-400c-953b-bfa554ceffb9
# ╟─f25beb99-386c-44e5-bb3e-ae621416810a
# ╠═b447f900-177a-11ef-1aff-578b4e55dd26
# ╠═d1085100-8d15-439c-8593-672a6d9387ee
# ╠═7ce6af5b-6c00-47ad-848a-e33523f0b619
# ╠═d56757ab-9e76-4c57-a473-bccf04941d67
# ╠═034b73c8-3f0b-46ca-b5bd-9a81677815f1
# ╠═1045af43-8200-411a-899f-46c646dfa5f2
# ╠═45596aac-1245-424e-9538-7f0f5257f87b
# ╟─1b429bc9-92ce-4d29-bff8-5861eef80958
# ╟─2b5c0f1e-816e-4a62-bbd6-f94a0b5dae5d
# ╟─71e65680-5eef-4b66-b518-8365e5314a91
# ╟─3115daec-7897-47ac-b72d-6d532e741224
# ╟─c1fcd87f-0d92-4fb9-a815-c103cf77611a
# ╟─618c35f7-dac0-4148-bf65-adfe85c4a8e1
# ╠═c3c3810a-793e-47e4-b406-5e2f7d3523e0
# ╠═96a37de7-0a96-48c6-b2d8-5a595db843c1
# ╠═a86ba704-91ba-428d-919e-052ff114198f
# ╠═108d1e00-6754-4d6e-aa63-0e5bb3588ac9
# ╠═a939bc07-1b32-4ca0-83f1-159613ed6ebf
# ╠═aee4bcb5-2e8d-4321-a9ee-1c1164b2e5ff
# ╠═fe005670-b7a1-4cba-8614-16d5d1569b8e
# ╠═74a16a95-fcbc-4616-9368-ebd52cca9540
# ╠═e62dd877-9705-413a-982b-515c0335e5d0
# ╠═bbb3ddd4-97dc-4646-a4be-0e8ff3372261
# ╠═3f5a148a-831d-400f-9e6a-19324e6c31f2
# ╟─d9baada1-5e99-400f-9356-2e0e3cd9b538
# ╟─0f672d40-1960-49f7-92e5-5bd901ba2d26
# ╠═9f43cb68-4fc6-4145-8804-5196cc7fd705
# ╠═3a859274-ec5a-4c71-93a9-c0e5f242680a
