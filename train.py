
import os
import torch
import torch.optim as optim
import torch.nn.functional as F
from torch.autograd import Variable
from cassandra_cluster import session
from torchvision import datasets, transforms
from redis import StrictRedis as redis
from common_functions import get_params_cass_async, get_params_cass_sync, set_params, get_params_redis, \
    push_params_cass, push_params_redis, get_params_memcache, push_params_memcache


# def train(rank, args, model):
# def train(args, model):
def train(args, model,shapes,db):

    torch.manual_seed(args.seed)
    train_loader = torch.utils.data.DataLoader(
        datasets.MNIST('../data', train=True, download=True,
                    transform=transforms.Compose([
                        transforms.ToTensor(),
                        transforms.Normalize((0.1307,), (0.3081,))
                    ])),
        batch_size=args.batch_size, shuffle=True, num_workers=1)
    test_loader = torch.utils.data.DataLoader(
        datasets.MNIST('../data', train=False, transform=transforms.Compose([
                        transforms.ToTensor(),
                        transforms.Normalize((0.1307,), (0.3081,))
                    ])),
        batch_size=args.batch_size, shuffle=True, num_workers=1)
    optimizer = optim.SGD(model.parameters(), lr=args.lr, momentum=args.momentum)
    # for epoch in range(1, args.epochs + 1):
    for epoch in range(1):
        # train_epoch(epoch, args, model, train_loader, optimizer)
        train_epoch(epoch, args, model, train_loader, optimizer,shapes,db)
        test_epoch(model, test_loader)


# def train_epoch(epoch, args, model, data_loader, optimizer):
def train_epoch(epoch, args, model, data_loader, optimizer, shapes, db):
    model.train()
    pid = os.getpid()
    for batch_idx, (data, target) in enumerate(data_loader):
        data, target = Variable(data), Variable(target)
        optimizer.zero_grad()
        # params = get_params_redis(db,shapes)
        params = get_params_memcache(db, shapes)
        set_params(model,params)
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        push_params_memcache(model,db)
        # push_params_redis(model,db)
        # push_params_cass(model)
        if batch_idx % args.log_interval == 0:
            print('{}\tTrain Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
                pid, epoch, batch_idx * len(data), len(data_loader.dataset),
                100. * batch_idx / len(data_loader), loss.data[0]))


def test_epoch(model, data_loader):
    model.eval()
    test_loss = 0
    correct = 0
    for data, target in data_loader:
        data, target = Variable(data, volatile=True), Variable(target)
        output = model(data)
        test_loss += F.nll_loss(output, target, size_average=False).data[0] # sum up batch loss
        pred = output.data.max(1)[1] # get the index of the max log-probability
        correct += pred.eq(target.data).cpu().sum()

    test_loss /= len(data_loader.dataset)
    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
        test_loss, correct, len(data_loader.dataset),
        100. * correct / len(data_loader.dataset)))