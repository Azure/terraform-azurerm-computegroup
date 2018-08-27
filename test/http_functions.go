package test

import (
	"io/ioutil"
	"net/http"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Open port 80 of virtual machines to allow HTTP request
func openPort80(t *testing.T) error {
	args := []string{"vm", "open-port", "--port", "80", "--resource-group", "linuxResourceGroup", "--name", "myvm0"}
	cmd := exec.Command("az", args...)
	err := cmd.Run()
	return err
}

// Get HTTP Response using public IP address
func getHTTPResponse(t *testing.T, publicIP string) (*http.Response, error) {
	target := "http://" + publicIP
	response, err := http.Get(target)
	if err != nil {
		return nil, err
	}

	return response, nil
}

// Check whether particular substring is contained in contents of HTTP response
func checkContents(t *testing.T, response *http.Response, substring string) error {
	contents, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return err
	}
	document := string(contents)
	isContained := strings.Contains(document, substring)
	assert.Equal(t, true, isContained)

	return nil
}
