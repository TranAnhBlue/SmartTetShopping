import '../../domain/entities/market.dart';
import '../../domain/repositories/market_repository.dart';
import '../local_db/dao/market_dao.dart';

class MarketRepositoryImpl implements MarketRepository {

  final MarketDao marketDao;

  MarketRepositoryImpl(this.marketDao);

  @override
  Future<List<Market>> getMarkets() async {
    final models = await marketDao.getAll();

    return models.map((m) => Market(
      id: m.id,
      name: m.name,
      location: m.location,
      zone: m.zone,
    )).toList();
  }

  @override
  Future<void> addMarket(Market market) {
    // TODO: implement addMarket
    throw UnimplementedError();
  }
}
