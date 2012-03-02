describe("TeamMember model", function() {
	var App.teamMembers;
	beforeEach(function () {
    App.teamMembers = new App.TeamMembers;
  });

	it("addTimetableItem", function() {
		// TimetableItem mock?


	});
  it("new: creates a new team member row", function() {
    
    console.log(App.teamMembers.length);
    expect(App.teamMembers.length).toEqual(0);
  });
  
});