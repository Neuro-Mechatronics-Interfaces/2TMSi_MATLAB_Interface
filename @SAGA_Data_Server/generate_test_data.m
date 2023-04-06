function generate_test_data(self)
%GENERATE_TEST_DATA  Generate random test data for development purposes

if ~self.Ready
    self.handle_init_push();
end

self.meta_data(1:20, [1 2]) = randn(20,2);

self.meta_data(1:5, 3) = 5;
self.meta_data(6:10,3) = 10;
self.meta_data(11:20,3) = 25;

self.meta_data(1:20,4) = [ones(10, 1).*30; ones(5,1).*50; ones(5,1).*45];
self.meta_data(1:20,5) = [repelem((0:1)', 5, 1); ones(10,1).*2];


self.sample_data(1:136,:,1:20) = randn(136,201,20);

end