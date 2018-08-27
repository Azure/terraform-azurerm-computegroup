package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformComputegroup(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture"

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the compute group allows public HTTP request through load balancer
	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// Make sure we can send HTTP request to the server
		testHTTPToServer(t, terraformOptions)
	})

	// At the end of the test, clean up any resources that were created
	test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

}

func configureTerraformOptions(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{},
	}

	return terraformOptions
}

func testHTTPToServer(t *testing.T, terraformOptions *terraform.Options) {
	// Get the value of an output variable
	publicIP := terraform.Output(t, terraformOptions, "public_ip_address")

	// It can take a minute or so for the web server to boot up, so retry a few times
	maxRetries := 15
	timeBetweenRetries := 5 * time.Second
	description := fmt.Sprintf("HTTP to %s", publicIP)

	// Verify that we can send HTTP request
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {
		// Get HTTP response from server
		response, err1 := getHTTPResponse(t, publicIP)
		if err1 != nil {
			return "", err1
		}

		// Check whether the content of HTTP response contains nginx
		defer response.Body.Close()
		substring := "nginx"
		err2 := checkContents(t, response, substring)
		if err2 != nil {
			return "", err2
		}
		fmt.Printf("HTTP found %s.\n", substring)

		return "", nil
	})
}
