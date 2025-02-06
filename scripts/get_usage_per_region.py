import boto3
import argparse


def fetch_detailed_usage(start_date, end_date, service_name, region):
    detailed_response = client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "USAGE_TYPE"}],
        Filter={
            "And": [
                {"Dimensions": {"Key": "SERVICE", "Values": [service_name]}},
                {"Dimensions": {"Key": "REGION", "Values": [region]}}
            ]
        }
    )
    return detailed_response.get("ResultsByTime", [])


def get_cost_and_usage(start_date, end_date, detailed, show_cost):
    total_cost = 0
    # Call AWS Cost Explorer API with grouping by REGION and SERVICE
    response = client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[
            {"Type": "DIMENSION", "Key": "REGION"},
            {"Type": "DIMENSION", "Key": "SERVICE"}
        ]
    )
    # Parse and display results
    cost_by_region = {}

    for result in response.get("ResultsByTime", []):
        for group in result.get("Groups", []):
            region = group["Keys"][0] if group["Keys"][0] else "Global"
            service_name = group["Keys"][1]
            cost = float(group["Metrics"]["UnblendedCost"]["Amount"])

            if cost > 0:
                if region not in cost_by_region:
                    cost_by_region[region] = []
                cost_by_region[region].append((service_name, cost))
                total_cost += cost

    # Print results per region
    for region, services in cost_by_region.items():
        print(f"\nRegion: {region}")
        for service, cost in services:
            if show_cost:
                print("  Service: {:50}  Cost: ${:3.2f}".format(service,cost))
            else:
                print(f'  Service: {service}')
            if detailed:
                details = fetch_detailed_usage(start_date, end_date, service, region)
                for detail_result in details:
                    for detail_group in detail_result.get("Groups", []):
                        usage_type = detail_group["Keys"][0]
                        usage_cost = float(detail_group["Metrics"]["UnblendedCost"]["Amount"])
                        if usage_cost > 0:
                            if show_cost:
                                print("    - Usage Type: {:34} Cost: ${:3.2f}".format(usage_type, usage_cost))
                            else:
                                print(f'    - Usage Type: {usage_type}')
                print("   ---")
        print("-" * 75)
    return total_cost


# Main section
if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Get AWS Cost and Usage per region.")
    parser.add_argument("--start-date", required=True, help="Start date in YYYY-MM-DD format.")
    parser.add_argument("--end-date", required=True, help="End date in YYYY-MM-DD format.")
    parser.add_argument("--detailed", action="store_true", help="Show detailed usage per service.")
    parser.add_argument("--show-cost", action="store_true", help="Show cost per service.")
    args = parser.parse_args()

    # Initialize AWS Cost Explorer client
    client = boto3.client("ce")
    
    print(f"AWS Used Services Report ({args.start_date} to {args.end_date}):\n")
    cost = get_cost_and_usage(args.start_date, args.end_date, args.detailed, args.show_cost)
    if args.show_cost:
        print(f'The total cost for the selected time period is ${cost:3.2f}\n')