// The functions that are prefixed with "special" is not intended to be reused in other projects!

const state_utils = {
  STATE_LOADING: 0,
  STATE_LOADED: 1,
  STATE_ERROR: -1,
  state: this.STATE_LOADED // by default,
};

state_utils.convertUIToLoadAppearance = () => {
  document.querySelectorAll(".visible_while_loading").forEach((e) => {
    e.style = "";
  });
  document.querySelectorAll(".visible_after_load_complete").forEach((e) => {
    e.style = "display: none;";
  });
  document.querySelector("#simple_error_display").style = "display: none;";
  this.state = this.STATE_LOADING;
};
state_utils.convertUIToLoadedAppearance = () => {
  document.querySelectorAll(".visible_while_loading").forEach((e) => {
    e.style = "display: none;";
  });
  document.querySelectorAll(".visible_after_load_complete").forEach((e) => {
    e.style = "";
  });
  document.querySelector("#simple_error_display").style = "display: none;";
  this.state = this.STATE_LOADED;
};
state_utils.convertUIToErrorAppearance = () => {
  document.querySelectorAll(".visible_while_loading").forEach((e) => {
    e.style = "display: none;";
  });
  document.querySelectorAll(".visible_after_load_complete").forEach((e) => {
    e.style = "display: none;";
  });
  document.querySelector("#simple_error_display").style = "";
  this.state = this.STATE_ERROR;
};